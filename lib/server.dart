import 'dart:async';

import 'core.dart';
import 'dart_api_gen.dart';

export 'package:dart_api_gen/dart_api_gen.dart';

abstract class ApiMiddleware {
  const ApiMiddleware();
  FutureOr<dynamic> apply(
      ApiRequest request, FutureOr<dynamic> Function(ApiRequest) next);
}

abstract class ApiRouter {
  List<ApiMiddleware> get middleware;
  ApiCodec get codec;

  FutureOr<dynamic> handle(ApiRequest request);

  FutureOr<dynamic> wrap(
    FutureOr<dynamic> Function(ApiRequest) fn,
    ApiRequest request,
  ) async {
    var iterator = middleware.iterator;
    FutureOr<dynamic> next(ApiRequest request) async {
      if (iterator.moveNext()) {
        return iterator.current.apply(request, next);
      } else {
        return fn(request);
      }
    }

    var result = next(request);
    if (result is Future) {
      result = await result;
    }

    return codec.encode(result);
  }
}
