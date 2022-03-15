import 'package:api_agent/clients/http_client.dart';
import 'package:api_agent_custom_types_example/shared/definitions.client.dart';
import 'package:api_agent_custom_types_example/shared/models.dart';

void main(List<String> args) async {
  var client = GreetApiClient(
    HttpApiClient(domain: 'http://localhost:8080'),
  );

  var result = await client.greet(args[0]);
  print(result.greeting);

  print(await client.sendGeneric<String>('Test'));
  print((await client.getGeneric<Value<int>>(15)).data);
}
