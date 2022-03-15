import 'package:api_agent/client.dart';

import 'definitions.api.dart';

export 'definitions.api.dart';

class GreetApiClient extends RelayApiClient {
  GreetApiClient(ApiClient client) : super('GreetApi', client);

  void greet(String name) => request('greet', {'name': name}, null);

  Stream<String> onGreeting() => request('onGreeting', {}, null);
}
