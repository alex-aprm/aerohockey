import 'dart:async';
import 'package:server/server.dart';

Future main() async {
  var server = new Server();
  await server.start();
}
