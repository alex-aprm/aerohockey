import 'dart:async';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:server/server.dart';
import 'package:shared/api.dart' as api;
import 'package:shared/shared.dart';

void main() {
  Server server;

  setUpAll(() async {
    server = new Server();
    await server.start();
    api.getClient = () => new http.Client();
    api.root = 'http://localhost:8084';
  });

  tearDownAll(() async {
    await server.stop();
  });

  test('get test', () async {
    var t1 = Model.randomString(128);
    api.token = t1;
    var p1 = await api.game.getCurrentPlayer();
    print(p1.name);
    await api.game.setCurrentPlayer(p1..name = 'test');

    api.token = 'abcd12';
    var p2 = await api.game.getCurrentPlayer();
    print(p2.name);

    api.token = t1;
    var p3 = await api.game.getCurrentPlayer();
    print(p3.name);

  });
}