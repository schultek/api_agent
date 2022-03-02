import 'package:api_agent/client.dart';

import 'definitions.api.dart';

export 'definitions.api.dart';

class GreetApiClient extends RelayApiClient {
  GreetApiClient(ApiClient client) : super('GreetApi', client);

  Future<String> greet(String name) => request('greet', {'name': name});
}
