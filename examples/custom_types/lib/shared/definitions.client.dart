import 'package:api_agent/client.dart';

import 'definitions.api.dart';
import 'models.dart';

export 'definitions.api.dart';

class GreetApiClient extends RelayApiClient {
  GreetApiClient(ApiClient client) : super('GreetApi', client, MapperCodec()) {
    useType('Value', <A>(f) => f<Value<A>>());
    useType('Data', (f) => f<Data>());
  }

  Future<Data> greet(String name) => request('greet', {'name': name}, null);

  Future<int> sendGeneric<T>(T data) =>
      request('sendGeneric', {'data': data}, ctx([T]));

  Future<T> getGeneric<T>(int value) =>
      request('getGeneric', {'value': value}, ctx([T]));
}
