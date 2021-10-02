import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart';

import '../client.dart';
import '../dart_api_gen.dart';
import '../src/api_exception.dart';
import 'http_request.dart';

export 'http_request.dart';

extension on HttpApiRequest {
  Request build() {
    return Request('post', Uri.parse(url))
      ..body = jsonEncode({
        'method': method,
        'params': encode(parameters),
        'data': encode(data),
      })
      ..headers.addAll(headers);
  }
}

mixin HttpApiClient on ApiClient {
  FutureOr<String> get domain;
  String get path;

  List<ApiProvider<HttpApiRequest>> get providers;

  @override
  Future<T> request<T>(String method, Map<String, dynamic> params) async {
    var domain = await this.domain;

    var request = (await HttpApiRequest(
      '$domain$path',
      method,
      params,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
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
    return codec.decode<T>(result);
  }
}
