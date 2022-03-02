import 'api_codec.dart';
import 'api_exception.dart';

class ApiRequest {
  final Map<String, dynamic> parameters;

  final Map<String, dynamic> context;
  final ApiCodec? codec;

  ApiRequest(this.parameters, {Map<String, dynamic>? context, this.codec})
      : context = context ?? {};

  ApiRequest change({Map<String, dynamic>? context, ApiCodec? codec}) {
    return ApiRequest(
      parameters,
      context: {...this.context, ...context ?? {}},
      codec: codec ?? this.codec,
    );
  }

  dynamic encode(dynamic value) {
    return codec != null ? codec!.encode(value) : value;
  }

  T decode<T>(dynamic value) {
    if (value is StringOrEncoded) value = value.decode<T>();
    return codec != null ? codec!.decode(value) : value as T;
  }

  T get<T>(String key) {
    if (parameters[key] == null) {
      throw ApiException(400, "Missing parameter '$key' of type $T.");
    }
    return decode(parameters[key]);
  }

  T? getOpt<T>(String key) => parameters[key] != null ? get<T>(key) : null;
}

class StringOrEncoded {
  StringOrEncoded(this.encoded, this.decoder);

  String encoded;
  dynamic Function(String) decoder;

  dynamic decode<T>() {
    if (T == String || T == dynamic) {
      return encoded;
    } else {
      return decoder(encoded);
    }
  }
}
