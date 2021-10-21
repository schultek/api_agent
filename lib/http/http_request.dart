import '../api_agent.dart';

extension HttpApiRequest on ApiRequest {
  String get url => context['url'] as String;
  Map<String, String> get headers => context['headers'] as Map<String, String>;

  static ApiRequest init(String url, Map<String, dynamic> params,
      {Map<String, dynamic>? context,
      Map<String, String>? headers,
      ApiCodec? codec}) {
    return ApiRequest(
      params,
      context: {
        'url': url,
        'headers': headers ?? <String, String>{},
        ...context ?? {}
      },
      codec: codec,
    );
  }
}
