import 'dart:async';
import 'dart:core';

import 'package:dart_api_gen/client.dart';

import 'api.dart';
import 'data.dart';
import 'mapper_transformer.dart';


abstract class SomeApiClientBase extends SomeApi with ApiClient {
  ApiCodec get codec => MapperCodec();

  /// [SomeApi.getData]
  Future<Data> getData(String id) => request('SomeApi.getData', {
    'id': id,
  });

  /// [SomeApi.testApi]
  Future<int> testApi(String data, [int? a, double b = 2]) => request('SomeApi.testApi', {
    'data': data,
    'a': a,
    'b': b,
  });

  /// [SomeApi.isOk]
  Future<bool> isOk({Data? d, required String b}) => request('SomeApi.isOk', {
    'd': d,
    'b': b,
  });
}
