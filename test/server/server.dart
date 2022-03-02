import 'dart:async';

import 'package:api_agent/servers/shelf_router.dart';
import 'package:shelf/shelf.dart';

import '../api/api.server.dart';
import 'middleware/auth_middleware.dart';

Handler buildApi() {
  return ShelfApiRouter([
    SomeApiEndpoint.from(
      getData: ApplyMiddleware(
        child: GetDataEndpoint.from((id, r) => Data('data_1:id=$id>>')),
        middleware: AuthMiddleware(),
      ),
      testApi: TestApi(),
      isOk: IsOk(),
      inner: InnerApi(),
    )
  ]);
}

class TestApi extends TestApiEndpoint {
  @override
  Future<int> testApi(String data, int? a, double b, ShelfApiRequest r) async {
    print('GET testApi (data: $data, a: $a, b: $b');
    return 0;
  }
}

class IsOk extends IsOkEndpoint {
  @override
  Future<bool> isOk(Data? d, String b, ApiRequest r) async {
    print('GET isOk (d: $d, b: $b');
    return true;
  }
}

class InnerApi extends InnerApiEndpoint {
  @override
  FutureOr<String> doSomething(int i, ApiRequest request) {
    return '$i';
  }
}
