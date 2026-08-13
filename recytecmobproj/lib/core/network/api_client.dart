import 'package:dio/dio.dart';
import 'package:recytecmobproj/core/network/api_exceptions.dart';
import '../config/env.dart';
import '../storage/secure_storage.dart';

class ApiClient {
  late final Dio dio;

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: Env.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: const {
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final token = await SecureStorage().readToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
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

  String _messageForError(DioException exception) {
    final data = exception.response?.data;
    if (data is Map && data.containsKey('message')) {
      final message = data['message'].toString().trim();
      if (message.isNotEmpty) return message;
    }

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
}
