import 'dart:async';

import 'package:dart_api_gen/dart_api_gen.dart';

import 'data.dart';
import 'mapper_transformer.dart';

@ApiDefinition(codec: MapperCodec())
abstract class SomeApi {
  Future<Data> getData(String id);

  Future<int> testApi(String data, [int? a, double b = 2]);

  Future<bool> isOk({Data? d, required String b});
}
