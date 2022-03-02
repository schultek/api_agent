import '../imports_builder.dart';

abstract class EndpointGenerator {
  String get endpointClassName;
  String get propertyName;
  String get abstractMemberDefinition;
  String get constructedEndpoint;

  void generate(
      StringBuffer output, Set<String> endpoints, ImportsBuilder imports);
}
