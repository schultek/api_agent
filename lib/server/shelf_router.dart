import 'dart:async';
import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:stack_trace/stack_trace.dart';

import '../server.dart';
import '../src/exception/api_exception.dart';

class ShelfApiRouter {
  List<ApiRouter> routers;

  ShelfApiRouter(this.routers);

  FutureOr<Response> call(Request request) async {
    var body = jsonDecode(await request.readAsString());
    var response = await _handleSingleRequest(body);
    return Response.ok(jsonEncode(response));
  }

  Future<Map> _handleSingleRequest(data) async {
    try {
      _validateRequest(data);

      var name = (data as Map)['method'] as String;
      var request = ApiRequest(
        name,
        data['params'] as Map<String, dynamic>,
        data: data['data'] as Map<String, dynamic>? ?? {},
      );

      Object? result;
      for (var handler in routers) {
        request.codec = handler.codec;
        try {
          result = await handler.handle(request);
          break;
        } on ApiException catch (error) {
          if (error.code != ErrorCodes.METHOD_NOT_FOUND) {
            rethrow;
          }
        }
      }

      if (result is Exception) {
        throw result;
      }

      return {'result': result};
    } on ApiException catch (error) {
      return {'error': error.toMap(data)};
    } catch (error, stackTrace) {
      final chain = Chain.forTrace(stackTrace);
      return {
        'error': ApiException(
          ErrorCodes.SERVER_ERROR,
          error.toString(),
          data: {'full': '$error', 'stack': '$chain'},
        ).toMap(data),
      };
    }
  }

  /// Validates that [request] matches the JSON-RPC spec.
  void _validateRequest(request) {
    if (request is! Map) {
      throw ApiException(
        ErrorCodes.INVALID_REQUEST,
        'Request must be an Array or an Object.',
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
