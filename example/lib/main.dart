// Shared api definitions

import 'package:api_agent/api_agent.dart';

@ApiDefinition()
abstract class GreetApi {
  Future<String> greet(String name);
}

// On the client

import 'package:api_agent/clients/http_client.dart';

Future<void> clientMain() async {
  var client = GreetApiClient(
    HttpApiClient(domain: 'http://localhost:8080'),
  );

  var result = await client.greet('James');
  print(result); // prints 'Hello James.';
}

// On the server

import 'package:api_agent/servers/shelf_router.dart';
import 'package:shelf/shelf_io.dart';

void serverMain() async {
  var api = ShelfApiRouter([
    GreetApiEndpoint.from(
      greet: GreetEndpoint.from((name, _) {
        return 'Hello $name.';
      }),
    ),
  ]);

  serve(api, InternetAddress.anyIPv4, 8080);
}
