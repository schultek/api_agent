import 'dart:async';

import 'core/api_codec.dart';
import 'core/api_request.dart';

export 'core/use_type.dart';

class ApiResponse {
  ApiResponse(this.value, {Map<String, dynamic>? context})
      : context = context ?? {};

  dynamic value;
  Map<String, dynamic> context;
}

abstract class ApiEndpoint<T> {
  void build(ApiBuilder builder);
}

typedef EndpointHandler = dynamic Function(ApiRequest request);

abstract class ApiBuilder {
  void mount(String prefix, List<ApiEndpoint> handlers);
  void handle(String prefix, EndpointHandler handler);
}

abstract class ApiMiddleware {
  FutureOr<dynamic> apply(covariant ApiRequest request, EndpointHandler next);
}

class ApplyMiddleware<T> extends WrappedEndpoint<T> implements ApiEndpoint<T> {
  ApplyMiddleware({
    required ApiEndpoint<T> child,
    required ApiMiddleware middleware,
  }) : super(child, (h) => (r) => middleware.apply(r, h));
}

extension WrapEndpoints on List<ApiEndpoint> {
  List<ApiEndpoint> wrap(EndpointHandler Function(EndpointHandler) f) {
    return map((h) => WrappedEndpoint(h, f)).toList();
  }

  List<ApiEndpoint> withCodec(ApiCodec codec) {
    return wrap(
        (h) => (r) async => codec.encode(await h(r.change(codec: codec))));
  }
}

class WrappedEndpoint<T> implements ApiEndpoint<T> {
  ApiEndpoint endpoint;
  EndpointHandler Function(EndpointHandler) fn;

  WrappedEndpoint(this.endpoint, this.fn);

  @override
  void build(ApiBuilder builder) => endpoint.build(WrappedBuilder(builder, fn));
}

class WrappedBuilder implements ApiBuilder {
  ApiBuilder visitor;
  EndpointHandler Function(EndpointHandler) fn;

  WrappedBuilder(this.visitor, this.fn);

  @override
  void handle(String prefix, EndpointHandler handler) =>
      visitor.handle(prefix, fn(handler));

  @override
  void mount(String prefix, List<ApiEndpoint> handlers) =>
      visitor.mount(prefix, handlers.wrap(fn));
}
