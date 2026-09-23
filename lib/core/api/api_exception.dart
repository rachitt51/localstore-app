import 'package:dio/dio.dart';

/// A failed API call. Either the API's error envelope
/// `{statusCode, code, message, details?}` or a transport failure
/// (`code == networkCode`).
class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.message,
    this.statusCode,
    this.details,
  });

  static const networkCode = 'NETWORK';
  static const unknownCode = 'UNKNOWN';

  factory ApiException.network([String? message]) => ApiException(
    code: networkCode,
    message: message ?? "Couldn't reach the store. Check your connection.",
  );

  /// Maps a [DioException] to an [ApiException]. Envelope fields are read
  /// leniently so an unexpected body still yields a usable message.
  factory ApiException.fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return ApiException.network();
      case DioExceptionType.cancel:
        return const ApiException(code: 'CANCELLED', message: 'Cancelled');
      default:
        break;
    }
    final status = e.response?.statusCode;
    final data = e.response?.data;
    if (data is Map) {
      final message = data['message'];
      return ApiException(
        code: data['code']?.toString() ?? unknownCode,
        message: message is List
            ? message.join('\n')
            : message?.toString() ?? 'Something went wrong',
        statusCode: (data['statusCode'] as num?)?.toInt() ?? status,
        details: data['details'],
      );
    }
    if (status == null) return ApiException.network();
    return ApiException(
      code: unknownCode,
      message: 'Request failed ($status)',
      statusCode: status,
    );
  }

  final String code;
  final String message;
  final int? statusCode;
  final Object? details;

  bool get isNetwork => code == networkCode;
  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => 'ApiException($code: $message)';
}

/// Message to show for any error thrown by a repository call.
String errorMessage(Object error) {
  if (error is ApiException) return error.message;
  if (error is DioException) return ApiException.fromDio(error).message;
  return 'Something went wrong';
}

bool isNetworkError(Object error) =>
    error is ApiException && error.isNetwork ||
    error is DioException && ApiException.fromDio(error).isNetwork;
