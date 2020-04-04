import 'dart:async';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:server/server.dart';
import 'package:shared/api.dart' as api;

void main() {

  Server server;

  setUpAll(() async {
    server = new Server();
    await server.start();
    api.getClient = () => new http.Client();
  });

  tearDownAll(() async {
    await server.stop();
  });

  test('get test', () async {
    var client = new api.HttpClient();
    var response = await client.get('http://localhost:8084/test');
    print(response.body);
  });
}