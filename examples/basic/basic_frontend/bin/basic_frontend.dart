import 'package:api_agent/clients/http_client.dart';
import 'package:basic_shared/definitions.client.dart';

void main(List<String> args) async {
  var client = GreetApiClient(
    HttpApiClient(domain: "http://localhost:8080"),
  );

  var result = await client.greet(args[0]);
  print(result);
}
