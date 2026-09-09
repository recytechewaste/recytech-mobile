import 'package:dio/dio.dart';
import 'package:recytecmobproj/core/network/api_exceptions.dart';
import '../config/env.dart';
import '../storage/secure_storage.dart';

class ApiClient {
  late final Dio dio;
  final SecureStorage _storage;

  ApiClient({Dio? dio, SecureStorage? storage})
      : _storage = storage ?? SecureStorage() {
    this.dio = dio ??
        Dio(
          BaseOptions(
            baseUrl: Env.baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            headers: const {
              'Content-Type': 'application/json',
            },
          ),
        );

    this.dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) async {
              try {
                await attachAuthorizationHeader(options);
              } catch (_) {
                // ignored during mock phase
              }
              handler.next(options);
            },
            onError: (DioException e, handler) {
              final int? statusCode = e.response?.statusCode;

              final String message = _messageForError(e);

              handler.reject(
                DioException(
                  requestOptions: e.requestOptions,
                  response: e.response,
                  type: e.type,
                  error: ApiException(
                    message,
                    statusCode: statusCode,
                  ),
                ),
              );
            },
          ),
        );
  }

  Future<void> attachAuthorizationHeader(RequestOptions options) async {
    if (options.headers.containsKey('Authorization')) return;
    final token = await _storage.readToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
  }

  String _messageForError(DioException exception) {
    final data = exception.response?.data;
    final responseMessage = responseErrorMessage(data);
    if (responseMessage != null) return responseMessage;

    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Please try again.';
      case DioExceptionType.connectionError:
        return 'Unable to connect. Check your internet or API base URL.';
      case DioExceptionType.badResponse:
        final statusCode = exception.response?.statusCode;
        if (statusCode == 401 || statusCode == 403) {
          return 'Your session has expired. Please sign in again.';
        }
        if (statusCode != null && statusCode >= 500) {
          return 'Server error. Please try again later.';
        }
        return exception.message ?? 'Request failed.';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.badCertificate:
        return 'Secure connection failed.';
      case DioExceptionType.unknown:
        return exception.message ?? 'Request failed.';
    }
  }

  /// Extracts the most useful validation message from the backend's supported
  /// JSON error shapes. UI sanitization still happens before display.
  static String? responseErrorMessage(dynamic data) {
    if (data is! Map) return null;

    final errors = data['errors'];
    if (errors is List && errors.isNotEmpty) {
      final first = errors.first;
      if (first is Map) {
        final validationMessage = (first['msg'] ?? '').toString().trim();
        if (validationMessage.isNotEmpty) return validationMessage;
      }
    }

    final message = (data['message'] ?? '').toString().trim();
    return message.isEmpty ? null : message;
  }
}
