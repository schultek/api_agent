import 'dart:async';

import 'package:api_agent/server.dart';

import 'api.dart';

export 'api.dart';

mixin _SomeApiEndpointMixin implements ApiEndpoint<SomeApiEndpoint> {
  List<ApiEndpoint> get endpoints;

  @override
  void build(ApiBuilder builder) {
    builder.mount('SomeApi', endpoints.withCodec(MapperCodec()));
  }
}

abstract class SomeApiEndpoint with _SomeApiEndpointMixin {
  static ApiEndpoint<SomeApiEndpoint> from({
    required ApiEndpoint<GetDataEndpoint> getData,
    required ApiEndpoint<TestApiEndpoint> testApi,
    required ApiEndpoint<IsOkEndpoint> isOk,
    required ApiEndpoint<InnerApiEndpoint> inner,
  }) =>
      _SomeApiEndpoint(getData, testApi, isOk, inner);

  FutureOr<Data> getData(String id, covariant ApiRequest request);

  FutureOr<int> testApi(
      String data, int? a, double b, covariant ApiRequest request);

  FutureOr<bool> isOk(Data? d, String b, covariant ApiRequest request);

  InnerApiEndpoint get inner;
  @override
  List<ApiEndpoint> get endpoints => [
        GetDataEndpoint.from(getData),
        TestApiEndpoint.from(testApi),
        IsOkEndpoint.from(isOk),
        inner,
      ];
}

class _SomeApiEndpoint with _SomeApiEndpointMixin {
  _SomeApiEndpoint(this.getDataEndpoint, this.testApiEndpoint,
      this.isOkEndpoint, this.innerEndpoint);
  final ApiEndpoint<GetDataEndpoint> getDataEndpoint;
  final ApiEndpoint<TestApiEndpoint> testApiEndpoint;
  final ApiEndpoint<IsOkEndpoint> isOkEndpoint;
  final ApiEndpoint<InnerApiEndpoint> innerEndpoint;
  @override
  List<ApiEndpoint> get endpoints =>
      [getDataEndpoint, testApiEndpoint, isOkEndpoint, innerEndpoint];
}

abstract class GetDataEndpoint implements ApiEndpoint<GetDataEndpoint> {
  GetDataEndpoint();
  factory GetDataEndpoint.from(
          FutureOr<Data> Function(String id, ApiRequest request) handler) =
      _GetDataEndpoint;
  FutureOr<Data> getData(String id, covariant ApiRequest request);
  @override
  void build(ApiBuilder builder) {
    builder.handle('getData', (r) => getData(r.get('id'), r));
  }
}

class _GetDataEndpoint extends GetDataEndpoint {
  _GetDataEndpoint(this.handler);

  final FutureOr<Data> Function(String id, ApiRequest request) handler;

  @override
  FutureOr<Data> getData(String id, covariant ApiRequest request) {
    return handler(id, request);
  }
}

abstract class TestApiEndpoint implements ApiEndpoint<TestApiEndpoint> {
  TestApiEndpoint();
  factory TestApiEndpoint.from(
      FutureOr<int> Function(String data, int? a, double b, ApiRequest request)
          handler) = _TestApiEndpoint;
  FutureOr<int> testApi(
      String data, int? a, double b, covariant ApiRequest request);
  @override
  void build(ApiBuilder builder) {
    builder.handle('testApi',
        (r) => testApi(r.get('data'), r.getOpt('a'), r.getOpt('b') ?? 2, r));
  }
}

class _TestApiEndpoint extends TestApiEndpoint {
  _TestApiEndpoint(this.handler);

  final FutureOr<int> Function(
      String data, int? a, double b, ApiRequest request) handler;

  @override
  FutureOr<int> testApi(
      String data, int? a, double b, covariant ApiRequest request) {
    return handler(data, a, b, request);
  }
}

abstract class IsOkEndpoint implements ApiEndpoint<IsOkEndpoint> {
  IsOkEndpoint();
  factory IsOkEndpoint.from(
      FutureOr<bool> Function(Data? d, String b, ApiRequest request)
          handler) = _IsOkEndpoint;
  FutureOr<bool> isOk(Data? d, String b, covariant ApiRequest request);
  @override
  void build(ApiBuilder builder) {
    builder.handle('isOk', (r) => isOk(r.getOpt('d'), r.get('b'), r));
  }
}

class _IsOkEndpoint extends IsOkEndpoint {
  _IsOkEndpoint(this.handler);

  final FutureOr<bool> Function(Data? d, String b, ApiRequest request) handler;

  @override
  FutureOr<bool> isOk(Data? d, String b, covariant ApiRequest request) {
    return handler(d, b, request);
  }
}

mixin _InnerApiEndpointMixin implements ApiEndpoint<InnerApiEndpoint> {
  List<ApiEndpoint> get endpoints;

  @override
  void build(ApiBuilder builder) {
    builder.mount('InnerApi', endpoints);
  }
}

abstract class InnerApiEndpoint with _InnerApiEndpointMixin {
  static ApiEndpoint<InnerApiEndpoint> from({
    required ApiEndpoint<DoSomethingEndpoint> doSomething,
  }) =>
      _InnerApiEndpoint(doSomething);

  FutureOr<String> doSomething(int i, covariant ApiRequest request);
  @override
  List<ApiEndpoint> get endpoints => [
        DoSomethingEndpoint.from(doSomething),
      ];
}

class _InnerApiEndpoint with _InnerApiEndpointMixin {
  _InnerApiEndpoint(this.doSomethingEndpoint);
  final ApiEndpoint<DoSomethingEndpoint> doSomethingEndpoint;
  @override
  List<ApiEndpoint> get endpoints => [doSomethingEndpoint];
}

abstract class DoSomethingEndpoint implements ApiEndpoint<DoSomethingEndpoint> {
  DoSomethingEndpoint();
  factory DoSomethingEndpoint.from(
          FutureOr<String> Function(int i, ApiRequest request) handler) =
      _DoSomethingEndpoint;
  FutureOr<String> doSomething(int i, covariant ApiRequest request);
  @override
  void build(ApiBuilder builder) {
    builder.handle('doSomething', (r) => doSomething(r.get('i'), r));
  }
}

class _DoSomethingEndpoint extends DoSomethingEndpoint {
  _DoSomethingEndpoint(this.handler);

  final FutureOr<String> Function(int i, ApiRequest request) handler;

  @override
  FutureOr<String> doSomething(int i, covariant ApiRequest request) {
    return handler(i, request);
  }
}
