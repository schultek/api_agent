import 'package:api_agent/api_agent.dart';

import 'models.dart';

@ApiDefinition(codec: MapperCodec(), useTypes: [Value])
abstract class GreetApi {
  Future<Data> greet(String name);

  Future<int> sendGeneric<T>(T data);

  Future<T> getGeneric<T>(int value);
}
