import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart';

import '../api_agent.dart';
import '../client.dart';
import '../src/api_exception.dart';
import '../src/case_style.dart';
import 'http_request.dart';

export 'http_request.dart';

extension RequestBuild on ApiRequest {
  Request build() {
    return Request('post', Uri.parse(url))
      ..body = jsonEncode({
        'params': encode(parameters),
        'context': encode(context),
      })
      ..headers.addAll(headers);
  }
}

class HttpApiClient implements ApiClient {
  FutureOr<String> domain;
  String path;
  List<ApiProvider> providers;
  ApiCodec? codec;

  HttpApiClient({
    required this.domain,
    required this.path,
    required this.providers,
    this.codec,
  });

  String segment(String s) {
    var out = CaseStyle.snakeCase.transform(s);
    return out.endsWith('_api') ? out.substring(0, out.length - 4) : out;
  }

  @override
  ApiClient mount(String prefix, [ApiCodec? codec]) {
    return HttpApiClient(
      domain: domain,
      path: '$path/${segment(prefix)}',
      providers: providers,
      codec: codec ?? this.codec,
    );
  }

  @override
  Future<T> request<T>(String method, Map<String, dynamic> params) async {
    var domain = await this.domain;

    var request = (await HttpApiRequest.init(
      '$domain$path/${segment(method)}',
      params,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      codec: codec,
    ).apply(providers))
        .build();

    StreamedResponse response;
    try {
      response = await request.send();
    } catch (e) {
      return Future.error(
          ApiException(-1, 'Could not make request: $e', data: request));
    }

    var code = response.statusCode;
    var body = await response.stream.bytesToString();

    if (code != 200) {
      return Future.error(ApiException(
        code,
        'Request to ${request.url} failed with status code ${response.statusCode}',
        data: body,
      ));
    }

    var json = jsonDecode(body);

    if (json['error'] != null) {
      return Future.error(
          ApiException.fromMap(json['error'] as Map<String, dynamic>));
    }

    if (T.toString() == 'void') {
      return null as T;
    }

    var result = json['result'];
    return codec != null ? codec!.decode<T>(result) : result as T;
  }
}
