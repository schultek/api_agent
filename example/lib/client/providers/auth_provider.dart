import 'dart:async';

import 'package:api_agent/api_agent.dart';
import 'package:api_agent/client.dart';

class AuthProvider extends ApiProvider {
  @override
  FutureOr<ApiRequest> apply(ApiRequest request) {
    return request..set('token', 'abc');
  }
}
