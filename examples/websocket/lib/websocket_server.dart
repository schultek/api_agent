import 'dart:async';
import 'dart:convert';

import 'package:api_agent/server.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

typedef ConnectionHandler = void Function(WebSocketChannel socket);

final _socketExpando = Expando<Map<String, dynamic>>();

class WebSocketRequest extends ApiRequest {
  final WebSocketChannel _socket;

  WebSocketRequest({
    required WebSocketChannel socket,
    required Map<String, dynamic> parameters,
    Map<String, dynamic>? context,
    ApiCodec? codec,
  })  : _socket = socket,
        super(parameters, context: context, codec: codec);

  @override
  WebSocketRequest change({
    Map<String, dynamic>? context,
    ApiCodec? codec,
  }) {
    return WebSocketRequest(
      socket: _socket,
      parameters: parameters,
      context: {...this.context, ...context ?? {}},
      codec: codec ?? this.codec,
    );
  }

  void setSocketContext(String key, dynamic value) {
    _socketExpando[_socket]![key] = value;
  }

  dynamic getSocketContext(String key) {
    return _socketExpando[_socket]![key];
  }
}

class WebSocketServer extends WebSocketPrefixHandler {
  late Handler _webSocketHandler;

  final ConnectionHandler? onConnection;

  WebSocketServer(
    List<ApiEndpoint> children, {
    this.onConnection,
  }) : super(children) {
    _webSocketHandler = webSocketHandler(this._onConnection);
  }

  void _onConnection(WebSocketChannel socket) {
    _socketExpando[socket] = {};
    onConnection?.call(socket);
    socket.stream.listen((message) {
      print('GOT MESSAGE ${message.runtimeType} $message');
      if (message is String) {
        var data = jsonDecode(message);
        var path = (data['event'] as String).split('/');
        messageHandlers[path.first]
            ?.onMessage(socket, path.skip(1), data['data']);
      }
    });
    messageHandlers.forEach((k, h) => h.setup([k], socket));
  }

  FutureOr<Response> call(Request request) => _webSocketHandler.call(request);
}

abstract class MessageHandler {
  void onMessage(WebSocketChannel socket, Iterable<String> path, dynamic data);
  void setup(Iterable<String> path, WebSocketChannel socket);
}

class WebSocketPrefixHandler implements ApiBuilder, MessageHandler {
  final Map<String, MessageHandler> messageHandlers = {};

  WebSocketPrefixHandler(List<ApiEndpoint> children) {
    children.forEach((c) => c.build(this));
  }

  @override
  void mount(String prefix, List<ApiEndpoint> handlers) {
    messageHandlers[prefix] = WebSocketPrefixHandler(handlers);
  }

  @override
  void handle(String prefix, EndpointHandler handler) {
    messageHandlers[prefix] = WebSocketEndpointHandler(handler);
  }

  @override
  void onMessage(WebSocketChannel socket, Iterable<String> path, data) {
    messageHandlers[path.first]?.onMessage(socket, path.skip(1), data);
  }

  @override
  void setup(Iterable<String> path, WebSocketChannel socket) {
    messageHandlers.forEach((k, h) => h.setup([...path, k], socket));
  }
}

class WebSocketEndpointHandler implements MessageHandler {
  final EndpointHandler endpoint;

  WebSocketEndpointHandler(this.endpoint);

  bool _isStream() {
    return endpoint is Stream Function(ApiRequest);
  }

  @override
  void onMessage(
      WebSocketChannel socket, Iterable<String> path, dynamic data) async {
    if (_isStream()) throw 'Cannot call streaming endpoint.';

    var request = WebSocketRequest(
        socket: socket, parameters: data as Map<String, dynamic>);
    await endpoint(request);
  }

  @override
  void setup(Iterable<String> path, WebSocketChannel socket) {
    var e = endpoint;
    if (e is Stream Function(ApiRequest)) {
      var stream = e(WebSocketRequest(socket: socket, parameters: {}));

      stream.listen((event) {
        socket.sink.add(jsonEncode({
          'event': path.join('/'),
          'data': event,
        }));
      });
    }
  }
}
