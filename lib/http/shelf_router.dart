import 'dart:async';
import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:stack_trace/stack_trace.dart';

import '../server.dart';
import '../src/api_exception.dart';
import '../src/case_style.dart';
import 'http_request.dart';
import 'http_response.dart';

class ShelfApiRouter implements ApiVisitor {
  final Router _router;

  ShelfApiRouter(List<ApiHandler> children) : _router = Router() {
    for (var h in children) {
      h.visit(this);
    }
  }

  String segment(String s) {
    var out = CaseStyle.snakeCase.transform(s);
    return out.endsWith('_api') ? out.substring(0, out.length - 4) : out;
  }

  @override
  void mount(String prefix, List<ApiHandler> children) {
    _router.mount('/${segment(prefix)}/', ShelfApiRouter(children));
  }

  @override
  void handle(String prefix, EndpointHandler handler) {
    _router.post('/${segment(prefix)}', wrap(handler));
  }

  Function wrap(EndpointHandler handler) {
    return (Request r) async {
      var body = jsonDecode(await r.readAsString());
      try {
        _validate(body);

        var request = HttpApiRequest.init(
          r.url.toString(),
          body['params'] as Map<String, dynamic>,
          context: body['context'] as Map<String, dynamic>? ?? {},
          headers: r.headers,
        );

        var response = await handler(request);

        if (response is ApiResponse) {
          if (response.value is Map<String, dynamic>) {
            return Response(
              response.statusCode,
              body: jsonEncode(response.value),
              headers: {
                'Content-Type': 'application/json',
                ...response.headers,
              },
            );
          } else {
            return Response(
              response.statusCode,
              body: response.value,
              headers: response.headers,
            );
          }
        } else {
          return Response.ok(jsonEncode({'result': response}));
        }
      } on ApiException catch (error) {
        return Response(
          error.code,
          body: jsonEncode({'error': error.toMap(body)}),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (error, stackTrace) {
        final chain = Chain.forTrace(stackTrace);
        return Response.internalServerError(
          body: jsonEncode({
            'error': ApiException(
              500,
              error.toString(),
              data: {'full': '$error', 'stack': '$chain'},
            ).toMap(body),
          }),
        );
      }
    };
  }

  FutureOr<Response> call(Request request) => _router.call(request);

  /// Validates the [request]
  static void _validate(request) {
    if (request is! Map) {
      throw ApiException(400, 'Request must be an Object.');
    }

    if (request.containsKey('params')) {
      var params = request['params'];
      if (params is! Map) {
        throw ApiException(400,
            'Request params must be an Object, but was ${jsonEncode(params)}.');
      }
    }
  }
}
