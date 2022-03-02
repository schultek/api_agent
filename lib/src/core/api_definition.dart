import 'api_codec.dart';

/// Used to annotate a class
/// in order to generate api code
class ApiDefinition {
  final ApiCodec? codec;
  const ApiDefinition({this.codec});
}
