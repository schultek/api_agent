import 'dart:async';

import 'package:dart_api_gen/server.dart';

extension UserContext on ApiRequest {
  String get user => data['user'] as String;
}

class AuthMiddleware extends ApiMiddleware {
  const AuthMiddleware();

  @override
  FutureOr<dynamic> apply(
      ApiRequest request, FutureOr<dynamic> Function(ApiRequest) next) {
    String token = request.getData('token');
    if (token == 'abc') {
      return next(request..set('user', 'abc'));
    } else {
      throw ApiException(401, 'Forbidden');
    }
  }
}
