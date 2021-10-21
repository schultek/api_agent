library api_agent;

import 'src/api_codec.dart';

export 'src/api_codec.dart';
export 'src/api_exception.dart';
export 'src/api_request.dart';

/// Used to annotate a class
/// in order to generate api code
class ApiDefinition {
  final ApiCodec? codec;
  const ApiDefinition({this.codec});
}
