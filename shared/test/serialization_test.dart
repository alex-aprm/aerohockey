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
    var game1 = new Game()..fromMap(m);

    expect(game1.id, game.id);
    expect(game1.blueSide.id, game.blueSide.id);
    expect(game1.blueSide.name, game.blueSide.name);
  });
}