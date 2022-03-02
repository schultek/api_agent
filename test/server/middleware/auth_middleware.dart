import 'dart:async';

import 'package:api_agent/servers/shelf_router.dart';

extension UserContext on ApiRequest {
  String get user => context['user'] as String;
}

class AuthMiddleware implements ApiMiddleware {
  @override
  FutureOr<dynamic> apply(ShelfApiRequest request, EndpointHandler next) {
    String? token = request.headers['Authorization'];
    if (token == 'abc') {
      return next(request.change(context: {'user': 'abc'}));
    } else {
      throw ApiException(
        401,
        'Authentication token is invalid.',
        data: {'token': token},
      );
    }
  }
}
