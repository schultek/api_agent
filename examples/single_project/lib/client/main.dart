import 'package:api_agent/clients/http_client.dart';

import '../api/api.client.dart';
import 'providers/auth_provider.dart';

Future<void> main() async {
  var client = SomeApiClient(HttpApiClient(
    domain: 'http://localhost:8081',
    path: '/api',
    providers: [AuthProvider()],
  ));

  var result = await client.getData('abc');
  print(result);

  print(await client.isOk(b: 'b'));
  print(await client.isOk(b: 'c', d: Data('asd')));

  print(await client.testApi('1', null));
  print(await client.testApi('2', 2, 3));

  print(await client.inner.doSomething(2));
}
