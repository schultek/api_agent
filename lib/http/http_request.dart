import '../dart_api_gen.dart';

class HttpApiRequest extends ApiRequest {
  String url;
  Map<String, String> headers;

  HttpApiRequest(this.url, String method, Map<String, dynamic> parameters,
      {Map<String, dynamic> data = const {},
      this.headers = const {},
      ApiCodec? codec})
      : super(method, parameters, data: data, codec: codec);
}
