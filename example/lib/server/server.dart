import 'dart:async';

import 'package:api_agent/http/shelf_router.dart';
import 'package:api_agent/server.dart';
import 'package:shelf/shelf.dart';

import '../api/api.dart';
import '../api/api.server.dart';
import 'middleware/auth_middleware.dart';

FutureOr<Response> Function(Request) buildApi() {
  return ShelfApiRouter([
    SomeApiHandler(
      getData: ApplyMiddleware(
        child: GetData(),
        middleware: AuthMiddleware(),
      ),
      testApi: TestApi(),
      isOk: IsOk(),
      inner: InnerApiHandler(
        doSomething: DoSomething(),
      ),
    )
  ]);
}

class GetData extends GetDataHandler {
  @override
  Future<Data> getData(String id, ApiRequest r) async {
    return Data('data_1:id=$id>>');
  }
}

class TestApi extends TestApiHandler {
  @override
  Future<int> testApi(String data, int? a, double b, ApiRequest r) async {
    print('GET testApi (data: $data, a: $a, b: $b');
    return 0;
  }
}

class IsOk extends IsOkHandler {
  @override
  Future<bool> isOk(Data? d, String b, ApiRequest r) async {
    print('GET isOk (d: $d, b: $b');
    return true;
  }
}

class DoSomething extends DoSomethingHandler {
  @override
  Future<String> doSomething(int i, ApiRequest r) async {
    return '$i';
  }
}
