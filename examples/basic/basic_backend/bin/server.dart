import 'dart:io';

import 'package:api_agent/servers/shelf_router.dart';
import 'package:basic_shared/definitions.server.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';

final _router = ShelfApiRouter([GreetApiImpl()]);

class GreetApiImpl extends GreetApiEndpoint {
  @override
  String greet(String name, ApiRequest _) {
    return 'Hello $name.';
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
