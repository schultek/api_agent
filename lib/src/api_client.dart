import 'dart:async';

import 'core/api_codec.dart';
import 'core/api_request.dart';

export 'core/use_type.dart';

abstract class ApiClient {
  R request<R>(
      String endpoint, Map<String, dynamic> params, RequestContext? context);
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
  T request<T>(
      String endpoint, Map<String, dynamic> params, RequestContext? context) {
    return parent.request(endpoint, params, context);
  }

  @override
  ApiClient mount(String prefix, [ApiCodec? codec]) {
    return parent.mount(prefix, codec);
  }

  RequestContext ctx([List<Type>? types]) {
    return RequestContext(types: types);
  }
}
