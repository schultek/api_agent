import 'dart:async';

import 'package:dart_api_gen/server.dart';

extension UserContext on ApiRequest {
  String get user => data['user'] as String;
}

class AuthMiddleware<T extends ApiResponse> extends ApiMiddleware<T> {
  const AuthMiddleware();

  @override
  FutureOr<T> apply(ApiRequest request, FutureOr<T> Function(ApiRequest) next) {
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
