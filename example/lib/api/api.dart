import 'dart:async';

import 'package:api_agent/api_agent.dart';

@ApiDefinition(codec: MapperCodec())
abstract class SomeApi {
  Future<Data> getData(String id);

  Future<int> testApi(String data, [int? a, double b = 2]);

  Future<bool> isOk({Data? d, required String b});

  InnerApi get inner;
}

abstract class InnerApi {
  Future<String> doSomething(int i);
}

class Data {
  String value;

  Data(this.value);

  @override
  String toString() {
    return 'Data{value: $value}';
  }
}

class MapperCodec extends ApiCodec {
  const MapperCodec();

  @override
  T decode<T>(dynamic value) {
    if (T == Data) {
      return Data(value as String) as T;
    }
    return value as T;
  }

  @override
  dynamic encode(dynamic value) {
    if (value is Data) {
      return value.value;
    } else if (value is Map) {
      return value.map((k, v) => MapEntry(k, encode(v)));
    }
    return value;
  }
}
