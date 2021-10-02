import 'dart:async';

import 'dart_api_gen.dart';

export 'dart_api_gen.dart';

abstract class ApiClient {
  Future<R> request<R>(String method, Map<String, dynamic> params);
  ApiCodec get codec;
}

abstract class ApiProvider<T extends ApiRequest> {
  FutureOr<T> apply(T request) => request;
}

extension RequestProvider<T extends ApiRequest> on T {
  FutureOr<T> apply(List<ApiProvider<T>> providers) async {
    return providers.fold(this, (r, p) async => p.apply(await r));
  }
}
