import 'dart:async';

import 'package:api_agent/server.dart';

import 'definitions.api.dart';
import 'models.dart';

export 'definitions.api.dart';

mixin _GreetApiEndpointMixin implements ApiEndpoint<GreetApiEndpoint> {
  List<ApiEndpoint> get endpoints;

  @override
  void build(ApiBuilder builder) {
    useType('Value', <A>(f) => f<Value<A>>());
    builder.mount('GreetApi', endpoints.withCodec(MapperCodec()));
  }
}

abstract class GreetApiEndpoint with _GreetApiEndpointMixin {
  static ApiEndpoint<GreetApiEndpoint> from({
    required ApiEndpoint<GreetEndpoint> greet,
    required ApiEndpoint<SendGenericEndpoint> sendGeneric,
    required ApiEndpoint<GetGenericEndpoint> getGeneric,
  }) =>
      _GreetApiEndpoint(greet, sendGeneric, getGeneric);

  FutureOr<Data> greet(String name, covariant ApiRequest request);

  FutureOr<int> sendGeneric<T>(T data, covariant ApiRequest request);

  FutureOr<T> getGeneric<T>(int value, covariant ApiRequest request);
  @override
  List<ApiEndpoint> get endpoints => [
        GreetEndpoint.from(greet),
        SendGenericEndpoint.from(sendGeneric),
        GetGenericEndpoint.from(getGeneric),
      ];
}

class _GreetApiEndpoint with _GreetApiEndpointMixin {
  _GreetApiEndpoint(
      this.greetEndpoint, this.sendGenericEndpoint, this.getGenericEndpoint);
  final ApiEndpoint<GreetEndpoint> greetEndpoint;
  final ApiEndpoint<SendGenericEndpoint> sendGenericEndpoint;
  final ApiEndpoint<GetGenericEndpoint> getGenericEndpoint;
  @override
  List<ApiEndpoint> get endpoints =>
      [greetEndpoint, sendGenericEndpoint, getGenericEndpoint];
}

abstract class GreetEndpoint implements ApiEndpoint<GreetEndpoint> {
  GreetEndpoint();
  factory GreetEndpoint.from(
          FutureOr<Data> Function(String name, ApiRequest request) handler) =
      _GreetEndpoint;
  FutureOr<Data> greet(String name, covariant ApiRequest request);
  @override
  void build(ApiBuilder builder) {
    builder.handle('greet', (r) => greet(r.get('name'), r));
  }
}

class _GreetEndpoint extends GreetEndpoint {
  _GreetEndpoint(this.handler);

  final FutureOr<Data> Function(String name, ApiRequest request) handler;

  @override
  FutureOr<Data> greet(String name, covariant ApiRequest request) {
    return handler(name, request);
  }
}

abstract class SendGenericEndpoint implements ApiEndpoint<SendGenericEndpoint> {
  SendGenericEndpoint();
  factory SendGenericEndpoint.from(
          FutureOr<int> Function<T>(T data, ApiRequest request) handler) =
      _SendGenericEndpoint;
  FutureOr<int> sendGeneric<T>(T data, covariant ApiRequest request);
  @override
  void build(ApiBuilder builder) {
    builder.handle('sendGeneric',
        (r) => r.invoke(<T>() => sendGeneric<T>(r.get('data'), r)));
  }
}

class _SendGenericEndpoint extends SendGenericEndpoint {
  _SendGenericEndpoint(this.handler);

  final FutureOr<int> Function<T>(T data, ApiRequest request) handler;

  @override
  FutureOr<int> sendGeneric<T>(T data, covariant ApiRequest request) {
    return handler<T>(data, request);
  }
}

abstract class GetGenericEndpoint implements ApiEndpoint<GetGenericEndpoint> {
  GetGenericEndpoint();
  factory GetGenericEndpoint.from(
          FutureOr<T> Function<T>(int value, ApiRequest request) handler) =
      _GetGenericEndpoint;
  FutureOr<T> getGeneric<T>(int value, covariant ApiRequest request);
  @override
  void build(ApiBuilder builder) {
    builder.handle('getGeneric',
        (r) => r.invoke(<T>() => getGeneric<T>(r.get('value'), r)));
  }
}

class _GetGenericEndpoint extends GetGenericEndpoint {
  _GetGenericEndpoint(this.handler);

  final FutureOr<T> Function<T>(int value, ApiRequest request) handler;

  @override
  FutureOr<T> getGeneric<T>(int value, covariant ApiRequest request) {
    return handler<T>(value, request);
  }
}
