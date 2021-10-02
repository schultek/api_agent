import 'dart:async';

import 'package:dart_api_gen/client.dart';
import 'package:dart_api_gen/http/http_client.dart';

import '../api/api.client.dart';
import 'providers/auth_provider.dart';

class SomeApiClient extends SomeApiClientBase with HttpApiClient {
  @override
  FutureOr<String> get domain => 'http://localhost:8080';

  @override
  String get path => '/api';

  @override
  List<ApiProvider<HttpApiRequest>> get providers => [AuthProvider()];
}
