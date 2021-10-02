import 'dart:async';
import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:stack_trace/stack_trace.dart';

import '../server.dart';
import '../src/api_exception.dart';

class HttpApiResponse extends ApiResponse {
  int statusCode;
  Map<String, String> headers;

  HttpApiResponse(this.statusCode, dynamic body, {this.headers = const {}})
      : super(body);

  HttpApiResponse.ok(dynamic body, {this.headers = const {}})
      : statusCode = 200,
        super(body);
}

mixin ShelfApiRouter on ApiRouter {
  List<ApiMiddleware<HttpApiResponse>> get middleware;

  @override
  FutureOr<HttpApiResponse> handle(ApiRequest request) async {
    var iterator = middleware.iterator;
    FutureOr<HttpApiResponse> next(ApiRequest request) async {
      if (iterator.moveNext()) {
        return iterator.current.apply(request, next);
      } else {
        return HttpApiResponse.ok({'result': await super.handle(request)});
      }
    }

    return next(request);
  }
}

class ShelfApiRouters {
  List<ShelfApiRouter> routers;

  ShelfApiRouters(this.routers);

  Future<Response> call(Request shelfRequest) async {
    var body = jsonDecode(await shelfRequest.readAsString());

    try {
      _validateRequest(body);

      var request = ApiRequest(
        body['method'] as String,
        body['params'] as Map<String, dynamic>,
        data: body['data'] as Map<String, dynamic>? ?? {},
      );

      for (var handler in routers) {
        request.codec = handler.codec;
        try {
          var response = await handler.handle(request);
          if (response.value is Map<String, dynamic>) {
            return Response(
              response.statusCode,
              body: jsonEncode(handler.codec.encode(response.value)),
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
        } on ApiException catch (error) {
          if (error.code != ErrorCodes.METHOD_NOT_FOUND) {
            rethrow;
          }
        }
      }

      throw ApiException.methodNotFound(request.method);
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
            ErrorCodes.SERVER_ERROR,
            error.toString(),
            data: {'full': '$error', 'stack': '$chain'},
          ).toMap(body),
        }),
      );
    }
  }

  /// Validates the [request]
  void _validateRequest(request) {
    if (request is! Map) {
      throw ApiException(
        ErrorCodes.INVALID_REQUEST,
        'Request must be an Object.',
      );
    }

    if (!request.containsKey('method')) {
      throw ApiException(
        ErrorCodes.INVALID_REQUEST,
        'Request must contain a "method" key.',
      );
    }

    var method = request['method'];
    if (request['method'] is! String) {
      throw ApiException(
        ErrorCodes.INVALID_REQUEST,
        'Request method must be a string, but was ${jsonEncode(method)}.',
      );
    }

    if (request.containsKey('params')) {
      var params = request['params'];
      if (params is! Map) {
        throw ApiException(
          ErrorCodes.INVALID_REQUEST,
          'Request params must be an Object, but was ${jsonEncode(params)}.',
        );
      }
    }
  }
}
