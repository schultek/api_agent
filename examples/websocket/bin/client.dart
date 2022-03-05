import 'package:api_agent_websocket_example/shared/definitions.client.dart';
import 'package:api_agent_websocket_example/websocket_client.dart';

void main(List<String> args) async {
  var client = GreetApiClient(
    await WebSocketClient.connect('ws://localhost:8080'),
  );

  client.onGreeting().listen((String msg) {
    print('GOT GREET $msg');
  });

  client.greet('Tom');
}
