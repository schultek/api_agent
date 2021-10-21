import 'dart:async';

import 'api_agent.dart';

export 'api_agent.dart';

abstract class ApiClient {
  Future<R> request<R>(String method, Map<String, dynamic> params);
  ApiClient mount(String prefix, [ApiCodec? codec]);
}

abstract class ApiProvider {
  FutureOr<ApiRequest> apply(ApiRequest request) => request;
}

extension RequestProvider on ApiRequest {
  FutureOr<ApiRequest> apply(List<ApiProvider> providers) async {
    return providers.fold(this, (r, p) async => p.apply(await r));
  }
}

abstract class ApiService {
  final ApiClient client;
  ApiService(String name, ApiClient client, [ApiCodec? codec])
      : client = client.mount(name, codec);

  Future<T> request<T>(String method, Map<String, dynamic> params) {
    return client.request(method, params);
  }
}
