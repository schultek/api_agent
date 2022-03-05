import 'package:api_agent/api_agent.dart';

@ApiDefinition()
abstract class GreetApi {
  void greet(String name);

  Stream<String> onGreeting();
}
