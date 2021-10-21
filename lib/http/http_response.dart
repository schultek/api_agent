import '../server.dart';

extension HttpApiResponse on ApiResponse {
  int get statusCode => context['statusCode'] as int;
  Map<String, String> get headers => context['headers'] as Map<String, String>;

  static ApiResponse init(int statusCode, dynamic body,
      {Map<String, String>? headers}) {
    return ApiResponse(body, context: {
      'statusCode': statusCode,
      'headers': headers ?? <String, String>{},
    });
  }

  static ApiResponse ok(dynamic body, {Map<String, String>? headers}) =>
      init(200, body, headers: headers);
}
