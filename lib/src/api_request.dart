import 'api_codec.dart';
import 'api_exception.dart';

class ApiRequest {
  final Map<String, dynamic> parameters;

  Map<String, dynamic> context;
  ApiCodec? codec;

  ApiRequest(this.parameters, {Map<String, dynamic>? context, this.codec})
      : context = context ?? {};

  void set(String key, dynamic value) {
    context = {...context, key: value};
  }

  dynamic encode(dynamic value) => codec != null ? codec!.encode(value) : value;
  T decode<T>(dynamic value) =>
      codec != null ? codec!.decode(value) : value as T;

  T get<T>(String key) {
    if (parameters[key] == null) {
      throw ApiException(400, "Missing parameter '$key' of type $T.");
    }
    return decode(parameters[key]);
  }

  T? getOpt<T>(String key) => parameters[key] != null ? get<T>(key) : null;
}
