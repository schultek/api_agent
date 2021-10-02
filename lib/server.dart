import 'dart:async';

import 'dart_api_gen.dart';

export 'dart_api_gen.dart';

abstract class ApiMiddleware<T extends ApiResponse> {
  const ApiMiddleware();
  FutureOr<T> apply(ApiRequest request, FutureOr<T> Function(ApiRequest) next);
}

class ApiResponse {
  dynamic value;
  ApiResponse(this.value);
}

abstract class ApiRouter {
  ApiCodec get codec;
  FutureOr<dynamic> handle(ApiRequest request);
}
