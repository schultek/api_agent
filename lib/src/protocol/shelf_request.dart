import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../../api_agent.dart';
import '../core/case_style.dart';

class ShelfApiRequest extends ApiRequest {
  ShelfApiRequest._({
    required this.url,
    required this.method,
    this.headers = const {},
    required Map<String, dynamic> parameters,
    Map<String, dynamic>? context,
    ApiCodec? codec,
  }) : super(parameters, context: context, codec: codec);

  final Uri url;
  final String method;
  final Map<String, String> headers;

  static Future<ShelfApiRequest> from(
    Request request,
    String method,
    String endpoint,
  ) async {
    Map<String, dynamic> params, context;

    if (method == 'POST') {
      var body = jsonDecode(await request.readAsString());

      _validate(body);

      params = body['params'] as Map<String, dynamic>;
      context = body['context'] as Map<String, dynamic>? ?? {};
    } else {
      params = request.requestedUri.queryParameters
          .map((k, v) => MapEntry(k, jsonDecode(v)));
      context = jsonDecode(request.headers['x-api-context'] ?? '{}')
          as Map<String, dynamic>;
    }

    return ShelfApiRequest._(
      url: request.requestedUri,
      method: method,
      headers: request.headers,
      parameters: params,
      context: context,
    );
  }

  static void _validate(request) {
    if (request is! Map) {
      throw ApiException(400, 'Request must be an Object.');
    }

    if (request.containsKey('params')) {
      var params = request['params'];
      if (params is! Map) {
        throw ApiException(400,
            'Request params must be an Object, but was ${jsonEncode(params)}.');
      }
    }
  }

  @override
  ShelfApiRequest change({
    Map<String, String>? headers,
    Map<String, dynamic>? context,
    ApiCodec? codec,
  }) {
    return ShelfApiRequest._(
      url: url,
      method: method,
      headers: {...this.headers, ...headers ?? {}},
      parameters: parameters,
      context: {...this.context, ...context ?? {}},
      codec: codec ?? this.codec,
    );
  }

  static String methodFor(String endpoint) {
    return CaseStyle.splitWords(endpoint).first.toLowerCase() == 'get'
        ? 'GET'
        : 'POST';
  }
}
