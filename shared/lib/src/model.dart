part of shared;

typedef dynamic PropertyGetter(Model m);
typedef PropertySetter(Model m, dynamic v);
typedef Model ModelConstructor();

abstract class Model {
  String id;

  void checkId() {
    id ??= new Uuid().v1();
  }

  Map<String, String> toJson() => toMap();

  void fromJson(String json) => fromMap(JSON.decode(json));

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

  static String pluralize(String s) {
    if (s[s.length - 1] == 'y')
      return s.substring(0, s.length - 1) + 'ies';
    else
      return s + 's';
  }

  static String camelToSnake(String str) => _fromCamel(str, '_');

  static String _fromCamel(String str, String separator) {
    if (str == null || str.length < 2) {
      return str;
    }
    int start = 0;
    final segments = <String>[];
    for (int i = 0; i < str.length; i++) {
      final char = str.substring(i, i + 1);
      final isUpper = char.toUpperCase() == char && char.toLowerCase() != char;
      if (isUpper) {
        segments.add(str.substring(start, i));
        start = i;
      }
    }
    segments.add(str.substring(start, str.length));
    return segments.map((s) => s.toLowerCase()).where((s) => s.isNotEmpty).join(separator);
  }

}

class ModelProperty {

  ModelProperty(this.type, this.name, this.get, this.set) {
    fieldName = Model.camelToSnake(ModelConstructors.containsKey(type) ? '${name}Id' : name);
  }

  String name;
  String fieldName;
  String type;
  PropertyGetter get;
  PropertySetter set;
  }

class AutoProperties {
  const AutoProperties();
}
