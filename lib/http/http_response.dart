import '../server.dart';

class HttpApiResponse extends ApiResponse {
  int statusCode;
  Map<String, String> headers;

  HttpApiResponse(this.statusCode, dynamic body, {this.headers = const {}})
      : super(body);

  HttpApiResponse.ok(dynamic body, {this.headers = const {}})
      : statusCode = 200,
        super(body);
}
