import 'dart:async';
import 'dart:io';

import 'package:api_agent_websocket_example/shared/definitions.server.dart';
import 'package:api_agent_websocket_example/websocket_server.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';

final _router = WebSocketServer([GreetApiImpl()]);

class GreetApiImpl extends GreetApiEndpoint {
  @override
  void greet(String name, WebSocketRequest request) {
    var controller = request.getSocketContext('controller');
    controller.add('Hello $name.');
  }

  @override
  Stream<String> onGreeting(WebSocketRequest request) {
    var controller = StreamController<String>();
    request.setSocketContext('controller', controller);
    return controller.stream;
  }
}

void main(List<String> args) async {
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  // Configure a pipeline that logs requests.
  final _handler = Pipeline().addMiddleware(logRequests()).addHandler(_router);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(_handler, ip, port);
  print('Server listening on port ${server.port}');
}
