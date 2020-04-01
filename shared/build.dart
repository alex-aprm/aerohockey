
import 'package:source_gen/source_gen.dart';
import 'package:generators/generators.dart';
import 'package:build_runner/build_runner.dart';

final List<BuildAction> phases = [
  new BuildAction(
      new PartBuilder (const [
        const PropertyGenerator()
      ]), 'shared')
];

void main(List<String> args) {
  build(phases, deleteFilesByDefault: true).then((msg) => print(msg));
}
