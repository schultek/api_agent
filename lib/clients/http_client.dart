import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart';

import '../client.dart';
import '../src/protocol/http_request.dart';

export '../client.dart';
export '../src/protocol/http_request.dart';

class HttpApiClient implements ApiClient {
  FutureOr<String> domain;
  String path;
  List<ApiProvider<HttpApiRequest>> providers;
  ApiCodec? codec;

  HttpApiClient({
    required this.domain,
    this.path = '/',
    this.providers = const [],
    this.codec,
  }) : assert(path.startsWith('/'));

  @override
  ApiClient mount(String prefix, [ApiCodec? codec]) {
    return HttpApiClient(
      domain: domain,
      path:
          '${path.endsWith('/') ? path : '$path/'}${HttpApiRequest.segment(prefix)}',
      providers: providers,
      codec: codec ?? this.codec,
    );
  }

  @override
  T request<T>(String endpoint, Map<String, dynamic> params) {
    var type = TypeAgent<T>();
    if (type.isA<Future>()) {
      return type.mapAs1<Future>(<T>() => _request<T>(endpoint, params));
    }
    throw 'Only endpoints that expect Futures are supported.';
  }

  Future<T> _request<T>(String endpoint, Map<String, dynamic> params) async {
    var domain = await this.domain;

    var request = HttpApiRequest(
      url: Uri.parse('$domain$path'),
      endpoint: endpoint,
      params: params,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      codec: codec,
    );

    var newRequest = await request.apply(providers);

    assert(
        newRequest is HttpApiRequest,
        'Providers should not change the type of an api request.'
        'Expected HttpApiRequest, got ${newRequest.runtimeType}');

    StreamedResponse response;
    try {
      response = await (newRequest as HttpApiRequest).build().send();
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

    if (T == typeOf<void>()) {
      return null as T;
    }

    var result = json['result'];
    return codec != null ? codec!.decode(result) : result as T;
  }
}
