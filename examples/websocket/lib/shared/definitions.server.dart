import 'dart:async';

import 'package:api_agent/server.dart';

import 'definitions.api.dart';

export 'definitions.api.dart';

mixin _GreetApiEndpointMixin implements ApiEndpoint<GreetApiEndpoint> {
  List<ApiEndpoint> get endpoints;

  @override
  void build(ApiBuilder builder) {
    builder.mount('GreetApi', endpoints);
  }
}

abstract class GreetApiEndpoint with _GreetApiEndpointMixin {
  static ApiEndpoint<GreetApiEndpoint> from({
    required ApiEndpoint<GreetEndpoint> greet,
    required ApiEndpoint<OnGreetingEndpoint> onGreeting,
  }) =>
      _GreetApiEndpoint(greet, onGreeting);

  void greet(String name, covariant ApiRequest request);

  Stream<String> onGreeting(covariant ApiRequest request);
  @override
  List<ApiEndpoint> get endpoints => [
        GreetEndpoint.from(greet),
        OnGreetingEndpoint.from(onGreeting),
      ];
}

class _GreetApiEndpoint with _GreetApiEndpointMixin {
  _GreetApiEndpoint(this.greetEndpoint, this.onGreetingEndpoint);
  final ApiEndpoint<GreetEndpoint> greetEndpoint;
  final ApiEndpoint<OnGreetingEndpoint> onGreetingEndpoint;
  @override
  List<ApiEndpoint> get endpoints => [greetEndpoint, onGreetingEndpoint];
}

abstract class GreetEndpoint implements ApiEndpoint<GreetEndpoint> {
  GreetEndpoint();
  factory GreetEndpoint.from(
      void Function(String name, ApiRequest request) handler) = _GreetEndpoint;
  void greet(String name, covariant ApiRequest request);
  @override
  void build(ApiBuilder builder) {
    builder.handle('greet', (r) => greet(r.get('name'), r));
  }
}

class _GreetEndpoint extends GreetEndpoint {
  _GreetEndpoint(this.handler);

  final void Function(String name, ApiRequest request) handler;

  @override
  void greet(String name, covariant ApiRequest request) {
    return handler(name, request);
  }
}

abstract class OnGreetingEndpoint implements ApiEndpoint<OnGreetingEndpoint> {
  OnGreetingEndpoint();
  factory OnGreetingEndpoint.from(
          Stream<String> Function(ApiRequest request) handler) =
      _OnGreetingEndpoint;
  Stream<String> onGreeting(covariant ApiRequest request);
  @override
  void build(ApiBuilder builder) {
    builder.handle('onGreeting', (r) => onGreeting(r));
  }
}

class _OnGreetingEndpoint extends OnGreetingEndpoint {
  _OnGreetingEndpoint(this.handler);

  final Stream<String> Function(ApiRequest request) handler;

  @override
  Stream<String> onGreeting(covariant ApiRequest request) {
    return handler(request);
  }
}
