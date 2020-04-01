import 'package:test/test.dart';
import 'package:shared/shared.dart';

void main() {
  test('serialization test' , () {
    var game = new Game()
        ..checkId()
        ..blueScore = 1
        ..redScore = 2
        ..blueSide = (
            new Player()..checkId()..name = 'Test');

    var m = game.toMap();
    expect(m['id'], game.id);
    expect(m['blueSide']['id'], game.blueSide.id);
    expect(m['blueSide']['name'], game.blueSide.name);
  });
}