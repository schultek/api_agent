import 'dart:async';

import 'package:api_agent/server.dart';

extension UserContext on ApiRequest {
  String? get token => context['token'] as String?;
  String get user => context['user'] as String;
}

class AuthMiddleware extends ApiMiddleware {
  const AuthMiddleware();

  @override
  FutureOr<dynamic> apply(
      ApiRequest request, FutureOr<dynamic> Function(ApiRequest) next) {
    String? token = request.token;
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
