import 'dart:convert';

import 'package:http/http.dart';

import '../../api_agent.dart';
import '../core/case_style.dart';

class HttpApiRequest extends ApiRequest {
  HttpApiRequest._(
      {required this.url,
      required this.method,
      this.headers = const {},
      required Map<String, dynamic> parameters,
      Map<String, dynamic>? context,
      ApiCodec? codec})
      : super(parameters, context: context, codec: codec);

  final Uri url;
  final String method;
  final Map<String, String> headers;

  factory HttpApiRequest({
    required Uri url,
    required String endpoint,
    required Map<String, dynamic> params,
    Map<String, dynamic>? context,
    Map<String, String>? headers,
    ApiCodec? codec,
  }) {
    String method = 'POST';
    var words = CaseStyle.splitWords(endpoint);

    if (words.first.toLowerCase() == 'get') {
      words.removeAt(0);
      method = 'GET';
    }

    return HttpApiRequest._(
      url: url.replace(path: url.path + '/' + words.join('_')),
      method: method,
      headers: headers ?? <String, String>{},
      parameters: params,
      context: context,
      codec: codec,
    );
  }

  @override
  HttpApiRequest change({
    Map<String, String>? headers,
    Map<String, dynamic>? context,
    ApiCodec? codec,
  }) {
    return HttpApiRequest._(
      url: url,
      method: method,
      headers: {...this.headers, ...headers ?? {}},
      parameters: parameters,
      context: {...this.context, ...context ?? {}},
      codec: codec ?? this.codec,
    );
  }

  static String segment(String s) {
    var out = CaseStyle.snakeCase.transform(s);
    return out.endsWith('_api') ? out.substring(0, out.length - 4) : out;
  }

  Request build() {
    var url = this.url;
    if (method == 'GET') {
      url = url.replace(
        queryParameters: parameters.mapValues(encode).mapValues(jsonEncode),
      );
    }
    var request = Request(method, url)..headers.addAll(headers);
    if (method == 'POST') {
      request.body = jsonEncode({
        'params': parameters.mapValues(encode),
        'context': context.mapValues(encode),
      });
    } else if (context.isNotEmpty) {
      request.headers['x-api-context'] = jsonEncode(context.mapValues(encode));
    }
    return request;
  }
}

extension MapValues<K, V> on Map<K, V> {
  Map<K, T> mapValues<T>(T Function(V) map) {
    return this.map((k, v) => MapEntry(k, map(v)));
  }
}
