import 'dart:async';

import 'package:dart_api_gen/server.dart';
import 'package:dart_api_gen/server/shelf_router.dart';

import '../api/api.server.dart';
import '../api/data.dart';
import 'middleware/auth_middleware.dart';

class SomeApiRouter extends SomeApiRouterBase with ShelfApiRouter {
  @override
  List<ApiMiddleware<HttpApiResponse>> get middleware => [AuthMiddleware()];

  @override
  Future<Data> getData(String id, ApiRequest request) async {
    return Data('data_1:id=$id>>');
  }

  @override
  Future<bool> isOk(ApiRequest request, {Data? d, required String b}) async {
    print('GET isOk (d: $d, b: $b');
    return true;
  }

  @override
  Future<int> testApi(String data, ApiRequest request,
      [int? a, double b = 2]) async {
    print('GET testApi (data: $data, a: $a, b: $b');
    return 0;
  }
}
