import '../server.dart';
import 'http_request.dart';
import 'http_response.dart';

export 'http_request.dart';
export 'http_response.dart';

abstract class HttpMiddleware
    extends ApiMiddleware<HttpApiRequest, HttpApiResponse> {
  const HttpMiddleware();
}
