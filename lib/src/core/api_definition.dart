import 'api_codec.dart';

/// Used to annotate a class
/// in order to generate api code
class ApiDefinition {
  const ApiDefinition({this.codec, this.useTypes});

  /// The codec to use for all child endpoints and apis
  final ApiCodec? codec;

  /// Optional list of types that can be provided to generic endpoints
  final List<Type>? useTypes;
}
