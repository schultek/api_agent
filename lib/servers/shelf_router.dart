import 'dart:async';
import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../server.dart';
import '../src/core/case_style.dart';
import '../src/protocol/shelf_request.dart';

export '../server.dart';
export '../src/protocol/shelf_request.dart';

class ShelfApiRouter implements ApiBuilder {
  final Router _router;

  ShelfApiRouter(List<ApiEndpoint> children) : _router = Router() {
    for (var h in children) {
      h.build(this);
    }
  }

  @override
  void mount(String prefix, List<ApiEndpoint> children) {
    _router.mount('/${_mountSegment(prefix)}/', ShelfApiRouter(children));
  }

  @override
  void handle(String endpoint, EndpointHandler handler) {
    var method = ShelfApiRequest.methodFor(endpoint);
    _router.add(
        method, '/${_pathSegment(endpoint)}', _wrap(method, endpoint, handler));
  }

  Function _wrap(String method, String endpoint, EndpointHandler handler) {
    return (Request r) async {
      try {
        var request = await ShelfApiRequest.from(r, method, endpoint);
        var response = await handler(request);

        if (response is Response) {
          return response;
        } else {
          return Response.ok(jsonEncode({'result': response}));
        }
      } on ApiException catch (error) {
        return Response(
          error.code,
          body: jsonEncode({
            'error': error.toMap({'uri': r.requestedUri.toString()})
          }),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (error, stackTrace) {
        return Response.internalServerError(
          body: jsonEncode({
            'error': ApiException(
              500,
              error.toString(),
              data: {'full': '$error', 'stack': '$stackTrace'},
            ).toMap(),
          }),
        );
      }
    };
  }

  FutureOr<Response> call(Request request) => _router.call(request);

  String _pathSegment(String s) {
    var out = CaseStyle.snakeCase.transform(s);
    if (out.startsWith('get_')) out = out.substring(4);
    return out;
  }

  String _mountSegment(String s) {
    var out = CaseStyle.snakeCase.transform(s);
    return out.endsWith('_api') ? out.substring(0, out.length - 4) : out;
  }
}
