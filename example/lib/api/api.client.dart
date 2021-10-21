import 'dart:async';
import 'dart:core';

import 'package:api_agent/client.dart';

import 'api.dart';

class SomeApiService extends ApiService {
  SomeApiService(ApiClient client) : super('SomeApi', client, MapperCodec());

  Future<Data> getData(String id) => request('getData', {'id': id});

  Future<int> testApi(String data, [int? a, double b = 2]) =>
      request('testApi', {'data': data, 'a': a, 'b': b});

  Future<bool> isOk({Data? d, required String b}) =>
      request('isOk', {'d': d, 'b': b});

  InnerApiService get inner => InnerApiService(client);
}

class InnerApiService extends ApiService {
  InnerApiService(ApiClient client) : super('InnerApi', client);

  Future<String> doSomething(int i) => request('doSomething', {'i': i});
}
