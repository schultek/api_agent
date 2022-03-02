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
  }) =>
      _GreetApiEndpoint(greet);

  FutureOr<String> greet(String name, covariant ApiRequest request);
  @override
  List<ApiEndpoint> get endpoints => [
        GreetEndpoint.from(greet),
      ];
}

class _GreetApiEndpoint with _GreetApiEndpointMixin {
  _GreetApiEndpoint(this.greetEndpoint);
  final ApiEndpoint<GreetEndpoint> greetEndpoint;
  @override
  List<ApiEndpoint> get endpoints => [greetEndpoint];
}

abstract class GreetEndpoint implements ApiEndpoint<GreetEndpoint> {
  GreetEndpoint();
  factory GreetEndpoint.from(
          FutureOr<String> Function(String name, ApiRequest request) handler) =
      _GreetEndpoint;
  FutureOr<String> greet(String name, covariant ApiRequest request);
  @override
  void build(ApiBuilder builder) {
    builder.handle('greet', (r) => greet(r.get('name'), r));
  }
}

class _GreetEndpoint extends GreetEndpoint {
  _GreetEndpoint(this.handler);

  final FutureOr<String> Function(String name, ApiRequest request) handler;

  @override
  FutureOr<String> greet(String name, covariant ApiRequest request) {
    return handler(name, request);
  }
}
