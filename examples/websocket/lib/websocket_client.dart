import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:api_agent/client.dart';

class _SubWSClient extends _WSClient {
  final _WSClient parent;
  final String prefix;

  _SubWSClient(this.parent, this.prefix) : super();

  R _request<R>(
      List<String> prefixes, String method, Map<String, dynamic> params) {
    return parent._request([...prefixes, prefix], method, params);
  }
}

abstract class _WSClient implements ApiClient {
  final Map<String, _WSClient> children;

  _WSClient() : children = {};

  @override
  ApiClient mount(String prefix, [ApiCodec? codec]) {
    return children[prefix] = _SubWSClient(this, prefix);
  }

  @override
  R request<R>(String method, Map<String, dynamic> params) {
    return _request([], method, params);
  }

  R _request<R>(
      List<String> prefixes, String method, Map<String, dynamic> params);
}

class WebSocketClient extends _WSClient {
  final WebSocket webSocket;

  final Map<String, Function> listeners = {};

  WebSocketClient._(this.webSocket) {
    webSocket.listen((message) {
      if (message is String) {
        var data = jsonDecode(message);

        var event = data['event'];
        listeners[event]?.call(data['data']);
      }
    });
  }

  static Future<WebSocketClient> connect(String url) async {
    var webSocket = await WebSocket.connect(url);
    return WebSocketClient._(webSocket);
  }

  R _request<R>(
      List<String> prefixes, String method, Map<String, dynamic> params) {
    var type = TypeAgent<R>();

    var event = [...prefixes, method].join('/');

    if (type.isA<Stream>()) {
      return type.mapAs1<Stream>(<T>() => _listen<T>(event, params));
    }

    if (type.isA<void>()) {
      return type.mapAs<void>(() => _send(event, params));
    }

    throw 'Websocket endpoints should have a return type of either Stream or void';
  }

  void _send(String event, Map<String, dynamic> data) {
    this.webSocket.add(jsonEncode({
          'event': event,
          'data': data,
        }));
  }

  Stream<T> _listen<T>(String event, Map<String, dynamic> params) {
    if (params.isNotEmpty) {
      throw 'Subscription endpoints must have no parameters.';
    }

    var controller = StreamController<T>();
    listeners[event] = (data) {
      controller.add(data as T);
    };
    return controller.stream;
  }
}
