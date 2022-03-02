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
