import 'dart:async';

import 'package:dart_api_gen/client.dart';
import 'package:dart_api_gen/dart_api_gen.dart';

class AuthProvider<T extends ApiRequest> extends ApiProvider<T> {
  @override
  FutureOr<T> apply(T request) {
    return request..set('token', 'abc');
  }
}
