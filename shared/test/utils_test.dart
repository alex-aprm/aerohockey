import 'package:test/test.dart';
import 'package:shared/shared.dart';

void main() {
  test('pluralize test', () {
    expect(Model.pluralize('Game'), 'Games');
    expect(Model.pluralize('Pony'), 'Ponies');
    expect(Model.camelToSnake('Pony'), 'pony');
    expect(Model.camelToSnake('PonyAreAlsoHorses'), 'pony_are_also_horses');
    expect(Model.camelToSnake(Model.pluralize(Model.camelToSnake('Game'))), 'games');
  });
}