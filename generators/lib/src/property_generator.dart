part of generators;

class PropertyGenerator extends GeneratorForAnnotation<AutoProperties> {
  const PropertyGenerator();

  Future<String> generate(LibraryReader library, buildStep) async {
    var elements = library.annotatedWith(typeChecker);
    var classes = await Future.wait(elements.map((e) async =>
    await generateForAnnotatedElement(e.element, e.annotation, buildStep)));
    var list =  await Future.wait(elements.map((dynamic e) async => e.element.name));
    List<String> out = [];
    if (list.isNotEmpty)
      out.add('Map<String,ModelConstructor> ModelConstructors = {${list.map((c) => '"$c": () => new $c()').join(',')}};');
    out.addAll(classes);
    return out.join('\n');
  }

  @override Future<String> generateForAnnotatedElement(Element element, ConstantReader annotation, _) async {
    print(element.name);
    var classElement = element as ClassElement;
    var className = classElement.name;
    var buffer = new StringBuffer();
    buffer.writeln('class \$$className { List<ModelProperty> properties = [');
    var names = new Set<String>();
    names.add('properties');
    for (var field in classElement.fields) {
      names.add(field.name);
      buffer.writeln('new ModelProperty("${field.type}", "${field.name}", (model) => model.${field
          .name}, (model, value) => model.${field.name} = value), ');
    }
    for (var field in classElement.supertype.element.fields) {
      if (names.contains(field.name))
        continue;
      buffer.writeln('new ModelProperty("${field.type}", "${field.name}", (model) => model.${field
          .name}, (model, value) => model.${field.name} = value), ');
    }
    buffer.writeln(']; }');
    return buffer.toString();
  }
}
