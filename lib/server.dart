import 'dart:async';

import 'api_agent.dart';

export 'api_agent.dart';

abstract class ApiMiddleware {
  const ApiMiddleware();
  FutureOr<dynamic> apply(
      ApiRequest request, FutureOr<dynamic> Function(ApiRequest) next);
}

class ApplyMiddleware<T> extends WrappedHandler<T> implements ApiHandler<T> {
  ApplyMiddleware({
    required ApiHandler<T> child,
    required ApiMiddleware middleware,
  }) : super(child, (h) => (r) => middleware.apply(r, h));
}

extension WrapHandlers on List<ApiHandler> {
  List<ApiHandler> wrap(EndpointHandler Function(EndpointHandler) f) {
    return map((h) => WrappedHandler(h, f)).toList();
  }

  List<ApiHandler> withCodec(ApiCodec codec) {
    return wrap((h) => (r) async => codec.encode(await h(r..codec = codec)));
  }
}

class WrappedHandler<T> implements ApiHandler<T> {
  ApiHandler handler;
  EndpointHandler Function(EndpointHandler) fn;

  WrappedHandler(this.handler, this.fn);

  @override
  void visit(ApiVisitor visitor) => handler.visit(WrappedVisitor(visitor, fn));
}

class WrappedVisitor implements ApiVisitor {
  ApiVisitor visitor;
  EndpointHandler Function(EndpointHandler) fn;

  WrappedVisitor(this.visitor, this.fn);

  @override
  void handle(String prefix, EndpointHandler handler) =>
      visitor.handle(prefix, fn(handler));

  @override
  void mount(String prefix, List<ApiHandler> handlers) =>
      visitor.mount(prefix, handlers.wrap(fn));
}

class ApiResponse {
  ApiResponse(this.value, {Map<String, dynamic>? context})
      : context = context ?? {};

  dynamic value;
  Map<String, dynamic> context;
}

typedef EndpointHandler = FutureOr<dynamic> Function(ApiRequest request);

abstract class ApiHandler<T> {
  void visit(ApiVisitor visitor);
}

typedef VisitMount = void Function(String prefix, List<ApiHandler> handlers);
typedef VisitHandle = void Function(String, EndpointHandler);

abstract class ApiVisitor {
  void mount(String prefix, List<ApiHandler> handlers);
  void handle(String prefix, EndpointHandler handler);
}
