import 'dart:async';
import 'dart:core';

import 'package:api_agent/server.dart';

import 'api.dart';

class SomeApiHandler implements ApiHandler<SomeApiHandler> {
  SomeApiHandler({
    required ApiHandler<GetDataHandler> getData,
    required ApiHandler<TestApiHandler> testApi,
    required ApiHandler<IsOkHandler> isOk,
    required ApiHandler<InnerApiHandler> inner,
  }) : endpoints = [getData, testApi, isOk, inner];

  final List<ApiHandler> endpoints;

  @override
  void visit(ApiVisitor visitor) =>
      visitor.mount('SomeApi', endpoints.withCodec(MapperCodec()));
}

abstract class GetDataHandler implements ApiHandler<GetDataHandler> {
  Future<Data> getData(String id, ApiRequest request);

  @override
  void visit(ApiVisitor visitor) =>
      visitor.handle('getData', (r) => getData(r.get('id'), r));
}

abstract class TestApiHandler implements ApiHandler<TestApiHandler> {
  Future<int> testApi(String data, int? a, double b, ApiRequest request);

  @override
  void visit(ApiVisitor visitor) => visitor.handle('testApi',
      (r) => testApi(r.get('data'), r.getOpt('a'), r.getOpt('b') ?? 2, r));
}

abstract class IsOkHandler implements ApiHandler<IsOkHandler> {
  Future<bool> isOk(Data? d, String b, ApiRequest request);

  @override
  void visit(ApiVisitor visitor) =>
      visitor.handle('isOk', (r) => isOk(r.getOpt('d'), r.get('b'), r));
}

class InnerApiHandler implements ApiHandler<InnerApiHandler> {
  InnerApiHandler({
    required ApiHandler<DoSomethingHandler> doSomething,
  }) : endpoints = [doSomething];

  final List<ApiHandler> endpoints;

  @override
  void visit(ApiVisitor visitor) => visitor.mount('InnerApi', endpoints);
}

abstract class DoSomethingHandler implements ApiHandler<DoSomethingHandler> {
  Future<String> doSomething(int i, ApiRequest request);

  @override
  void visit(ApiVisitor visitor) =>
      visitor.handle('doSomething', (r) => doSomething(r.get('i'), r));
}
