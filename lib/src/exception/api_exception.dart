import 'error_codes.dart';

export 'error_codes.dart';

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
