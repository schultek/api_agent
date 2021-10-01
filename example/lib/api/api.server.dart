import 'dart:async';
import 'dart:core';

import 'package:dart_api_gen/server.dart';

import 'api.dart';
import 'data.dart';
import 'mapper_transformer.dart';

abstract class SomeApiRouterBase extends ApiRouter {
  ApiCodec get codec => MapperCodec();

  /// [SomeApi.getData]
  Future<Data> getData(String id, ApiRequest request);

  /// [SomeApi.testApi]
  Future<int> testApi(String data, ApiRequest request, [int? a, double b = 2]);

  /// [SomeApi.isOk]
  Future<bool> isOk(ApiRequest request, {Data? d, required String b});

  @override
  dynamic handle(ApiRequest r) {
    switch (r.method) {
      case 'SomeApi.getData':
        return wrap(
            (r) => getData(
                  r.get('id'),
                  r,
                ),
            r);
      case 'SomeApi.testApi':
        return wrap(
            (r) => testApi(
                  r.get('data'),
                  r,
                  r.getOpt('a'),
                  r.getOpt('b') ?? 2,
                ),
            r);
      case 'SomeApi.isOk':
        return wrap(
            (r) => isOk(
                  r,
                  d: r.getOpt('d'),
                  b: r.get('b'),
                ),
            r);
      default:
        throw ApiException.methodNotFound(r.method);
    }
  }
}
