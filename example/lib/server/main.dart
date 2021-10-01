import 'dart:io';

import 'package:dart_api_gen/server/shelf_router.dart';
import 'package:shelf/shelf.dart' hide Server;
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

import 'server.dart';

Future<void> main() async {
  var router = Router();
  router.all('/ping', (_) => Response.ok('pong'));

  router.post('/api', ShelfApiRouter([SomeApiRouter()]));

  router.all('/<path|.*>', (_, path) => Response.notFound('Not Found'));

  Future<Response> handler(Request request) async {
    print('Request made to ${request.url.path} ...');
    var time = DateTime.now();
    Response resp;
    try {
      resp = await router(request);
    } catch (e, st) {
      print('Error on handling ${request.requestedUri}: $e');
      print(st);
      resp = Response.internalServerError(body: e.toString());
    }
    print(
        'Request to ${request.url.path} finished in ${DateTime.now().difference(time)}');
    return resp.change(headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': '*',
      'Access-Control-Expose-Headers': '*',
    });
  }

  // Find port to listen on from environment variable.
  var port = int.parse(Platform.environment['PORT'] ?? '8080');
  var app = const Pipeline().addMiddleware(logRequests()).addHandler(handler);

  // Serve handler on given port.
  var server = await serve(app, InternetAddress.anyIPv4, port, shared: true);
  print('Serving at http://${server.address.host}:${server.port}');
}
