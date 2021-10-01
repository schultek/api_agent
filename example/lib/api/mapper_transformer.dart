import 'package:dart_api_gen/dart_api_gen.dart';

import 'data.dart';

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
