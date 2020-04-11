part of server;

class DbRepository<M extends Model> {

  final DbContext db;

  String table;
  String type;
  M instance;

  DbRepository(this.db) {
    type = M.toString();
    table = Model.pluralize(Model.camelToSnake(type));
    instance = ModelConstructors[type]();
  }

  DbQuery<M> query() => newQuery();

  DbQuery<M> where(String whereString, Map whereParams) => newQuery().where(whereString, whereParams);

  Future<M> save(M model) => newQuery().save(model);

  Future<M> delete(M model) => newQuery().delete(model);

  Future<M> find(String id) => newQuery().find(id);

  Future<List<M>> get() => newQuery().get();

  DbQuery newQuery() => new DbQuery<M>(db, type, table, instance);

  Future createTable() => db.run((db) async {
    String getFieldDeclaration(ModelProperty property) {
      var s = property.fieldName;
      if (property.type == 'String')
        s += property.name == 'id' ? ' uuid primary key' : ' text';
      else if (property.type == 'int')
        s += ' int';
      else if (property.type == 'DateTime')
        s += ' timestamp without time zone';
      else if (ModelConstructors.containsKey(property.type)) {
        s += ' uuid';
      }
      return s;
    }
    try {
      var q = 'create table ${Model.pluralize(Model.camelToSnake(type))}(${instance.properties.map(getFieldDeclaration)
          .join(', ')})';
      await db.sql(q, {});
    } catch (_) {
      // table already exists, nothing to worry about
    }
  });
}

class DbQuery<M extends Model> {

  final DbContext db;

  String table;
  String type;
  M instance;
  String whereString;
  Map whereParams = {};

  DbQuery(this.db, this.type, this.table, this.instance);

  DbQuery where(String whereString, Map whereParams) {
    whereString = whereString;
    whereParams = whereParams;
    return this;
  }

  Future<List<M>> get() => db.run((db) async {
    var fieldsList = instance.properties.map((p) => p.fieldName);
    whereString ??= '';
    if (whereString.isNotEmpty)
      whereString = 'where $whereString';
    var data = await db.sql('select ${fieldsList.join(', ')} from $table $whereString', whereParams);
    List<M> results = [];
    if (data.isNotEmpty)
      for (var i = 0; i < data['id'].length; i++)
        results.add(_map(data, i));
    return results;
  });

  Future<M> find(String id) => db.run((db) async {
      var fieldsList = instance.properties.map((p) => p.fieldName);
      var data = await db.sql('select ${fieldsList.join(', ')} from $table where id = @id', {'id': id});
      if (data.isEmpty)
        return null;
      return _map(data, 0);
    });

  Model _map(Map<String, List> data, int i) {
    var model = ModelConstructors[type]();
    for(var p in model.properties) {
      if (ModelConstructors.containsKey(p.type)) {
        p.set(model, ModelConstructors[p.type]()..id = data[p.fieldName][i]);
      } else {
        p.set(model, data[p.fieldName][i]);
      }
    }
    return model;
  }

  Future<M> save(M model) => db.run((db) async {
    var fieldsList = instance.properties.map((p) => p.fieldName);
    var updateStr = fieldsList.map((f) => '$f = @$f').join(', ');
    var s = 'insert into $table(${fieldsList.join(', ')}) values(${fieldsList.map((f) => '@$f').join(', ')}) on conflict(id) do update set $updateStr';
    var m = new Map.fromIterable(instance.properties, key: (p) => p.fieldName, value: (p) {
      var v = p.get(model);
      return ModelConstructors.containsKey(p.type) ? v?.id : v;
    });
    await db.sql(s, m);
    return model;
  });

  Future<M> delete(M model) => db.run((db) async {
    await db.sql('delete from $table where id = @id', {'id': model.id});
    return model;
  });

}