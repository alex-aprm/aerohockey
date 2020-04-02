part of shared;
typedef dynamic PropertyGetter(Model m);
typedef PropertySetter(Model m, dynamic v);
typedef Model ModelConstructor();

abstract class Model {
  String id;

  void checkId() {
    id ??= new Uuid().v1();
  }

  Map toMap() {
    return new Map.fromIterable(properties, key: (p) => p.name, value: (ModelProperty p) {
      var value = p.get(this);
      if (p.type == 'String' || p.type == 'int')
        return value;
      if (p.type == 'DateTime')
        return value?.toUtc()?.toIso8601String();
      if (value is Model)
        return value?.toMap();
      return value.toString();
    });
  }
  void fromMap(Map map) {
    for(var p in properties) {
      var value = map[p.name];
      if (p.type == 'String' || p.type == 'int')
        p.set(this, value);
      if (p.type == 'DateTime')
        p.set(this, parseDateTime(value));
      if (value is Map)
        p.set(this, ModelConstructors[p.type]()..fromMap(value));
    }
  }

  DateTime parseDateTime(String s) {
    if (s == null)
      return null;
    return DateTime.parse(s);
  }

  Iterable<ModelProperty> properties;
}

class ModelProperty {

  ModelProperty(this.type, this.name, this.get, this.set);

  String name;
  String type;
  PropertyGetter get;
  PropertySetter set;
}