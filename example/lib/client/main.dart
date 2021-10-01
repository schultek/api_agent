import '../api/data.dart';
import 'client.dart';

Future<void> main() async {
  var client = SomeApiClient();

  var result = await client.getData('abc');
  print(result);

  print(await client.isOk(b: 'b'));
  print(await client.isOk(b: 'c', d: Data('asd')));

  print(await client.testApi('1', null));
  print(await client.testApi('2', 2, 3));
}
