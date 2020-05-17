import 'dart:async';
import 'dart:io';
import 'package:server/server.dart';

Future main(List<String> args) async {
  if (args.isNotEmpty) {
    if (args[0] == 'start') {
      await Process.start('dart', ['start_server.dart']);
      exit(0);
    }
  }
  var server = new Server();
  await server.start();
}
