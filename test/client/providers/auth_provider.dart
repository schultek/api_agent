import 'dart:async';

import 'package:api_agent/clients/http_client.dart';

class AuthProvider extends ApiProvider<HttpApiRequest> {
  @override
  FutureOr<HttpApiRequest> apply(HttpApiRequest request) {
    return request.change(headers: {'Authorization': 'abc'});
  }
}
