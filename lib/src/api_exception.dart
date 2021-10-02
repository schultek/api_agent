// ignore_for_file: constant_identifier_names

class ApiException implements Exception {
  /// The error code.
  ///
  /// All non-negative error codes are available for use by application
  /// developers.
  final int code;

  /// The error message.
  ///
  /// This should be limited to a concise single sentence. Further information
  /// should be supplied via [data].
  final String message;

  /// Extra application-defined information about the error.
  ///
  /// This must be a JSON-serializable object. If it's a [Map] without a
  /// `"request"` key, a copy of the request that caused the error will
  /// automatically be injected.
  final dynamic data;

  ApiException(this.code, this.message, {this.data});

  /// An exception indicating that the method named [methodName] was not found.
  ///
  /// This should usually be used only by fallback handlers.
  ApiException.methodNotFound(String methodName)
      : this(ErrorCodes.METHOD_NOT_FOUND, 'Unknown method "$methodName".');

  /// An exception indicating that the parameters for the requested method were
  /// invalid.
  ///
  /// Methods can use this to reject requests with invalid parameters.
  ApiException.invalidParams(String message)
      : this(ErrorCodes.INVALID_PARAMS, message);

  Map<String, dynamic> toMap([dynamic request]) {
    return {
      'code': code,
      'message': message,
      'data': data is Map ? {'request': request, ...data} : data,
    };
  }

  factory ApiException.fromMap(Map<String, dynamic> map) {
    return ApiException(
      map['code'] as int,
      map['message'] as String,
      data: (map['data'] as Map<String, dynamic>? ?? {}),
    );
  }

  @override
  String toString() {
    return 'ApiException{code: $code, message: $message, data: $data}';
  }
}

class ErrorCodes {
  /// An error code indicating that invalid JSON was received by the server.
  static const PARSE_ERROR = -32700;

  /// An error code indicating that the request JSON was invalid according to the
  /// JSON-RPC 2.0 spec.
  static const INVALID_REQUEST = -32600;

  /// An error code indicating that the requested method does not exist or is
  /// unavailable.
  static const METHOD_NOT_FOUND = -32601;

  /// An error code indicating that the request parameters are invalid for the
  /// requested method.
  static const INVALID_PARAMS = -32602;

  /// An internal JSON-RPC error.
  static const INTERNAL_ERROR = -32603;

  /// An unexpected error occurred on the server.
  ///
  /// The spec reserves the range from -32000 to -32099 for implementation-defined
  /// server exceptions, but for now we only use one of those values.
  static const SERVER_ERROR = -32000;

  /// Returns a human-readable name for [errorCode] if it's one specified by the
  /// JSON-RPC 2.0 spec.
  ///
  /// If [errorCode] isn't defined in the JSON-RPC 2.0 spec, returns null.
  String? name(int errorCode) {
    switch (errorCode) {
      case PARSE_ERROR:
        return 'parse error';
      case INVALID_REQUEST:
        return 'invalid request';
      case METHOD_NOT_FOUND:
        return 'method not found';
      case INVALID_PARAMS:
        return 'invalid parameters';
      case INTERNAL_ERROR:
        return 'internal error';
      default:
        return null;
    }
  }
}
