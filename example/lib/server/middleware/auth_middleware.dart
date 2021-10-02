import 'dart:async';

import 'package:dart_api_gen/http/http_middleware.dart';
import 'package:dart_api_gen/server.dart';

extension UserContext on ApiRequest {
  String get user => data['user'] as String;
}

class AuthMiddleware extends HttpMiddleware {
  const AuthMiddleware();

  @override
  FutureOr<HttpApiResponse> apply(HttpApiRequest request,
      FutureOr<HttpApiResponse> Function(HttpApiRequest) next) {
    String token = request.getData('token');
    if (token == 'abc') {
      return next(request..set('user', 'abc'));
    } else {
      throw ApiException(
        401,
        'Authentication token is invalid.',
        data: {'token': token},
      );
    }
  }
}
