import 'package:api_agent/api_agent.dart';
import 'package:dart_mappable/dart_mappable.dart';

import 'models.mapper.g.dart';

@MappableClass()
class Data {
  String greeting;
  Data(this.greeting);
}

@MappableClass()
class Value<T> {
  T data;

  Value(this.data);
}

class MapperCodec extends ApiCodec {
  const MapperCodec();

  @override
  T decode<T>(value) => Mapper.fromValue(value);

  @override
  encode(value) => Mapper.toValue(value);
}
