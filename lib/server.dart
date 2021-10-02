import 'dart:async';

import 'dart_api_gen.dart';

export 'dart_api_gen.dart';

abstract class ApiMiddleware<Request extends ApiRequest,
    Response extends ApiResponse> {
  const ApiMiddleware();
  FutureOr<Response> apply(
      Request request, FutureOr<Response> Function(Request) next);
}

class ApiResponse {
  dynamic value;
  ApiResponse(this.value);
}

abstract class ApiRouter {
  ApiCodec get codec;
  FutureOr<dynamic> handle(ApiRequest request);
}
