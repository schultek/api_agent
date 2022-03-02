import 'dart:async';

import 'core/api_codec.dart';
import 'core/api_request.dart';

abstract class ApiClient {
  Future<R> request<R>(String method, Map<String, dynamic> params);
  ApiClient mount(String prefix, [ApiCodec? codec]);
}

abstract class ApiProvider<T extends ApiRequest> {
  FutureOr<T> apply(T request) => request;
}

extension RequestProvider on ApiRequest {
  FutureOr<ApiRequest> apply(List<ApiProvider> providers) async {
    return providers.fold(this, (r, p) async => p.apply(await r));
  }
}

abstract class RelayApiClient implements ApiClient {
  final ApiClient parent;
  RelayApiClient(String name, ApiClient parent, [ApiCodec? codec])
      : parent = parent.mount(name, codec);

  @override
  Future<T> request<T>(String method, Map<String, dynamic> params) {
    return parent.request(method, params);
  }

  @override
  ApiClient mount(String prefix, [ApiCodec? codec]) {
    return parent.mount(prefix, codec);
  }
}
