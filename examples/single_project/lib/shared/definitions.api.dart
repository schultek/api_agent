import 'package:api_agent/api_agent.dart';

@ApiDefinition()
abstract class GreetApi {
  Future<String> greet(String name);
}
