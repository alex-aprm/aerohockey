import 'dart:convert';
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

    var s = JSON.encode(game);
    print(s);
  });

  test('engine serialization test' , () {
   var engine = new Engine();
   engine.init();
   var s = engine.toString();
   engine.fromString(s);
  });

}