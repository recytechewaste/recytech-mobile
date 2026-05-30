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

          final String message = e.response?.data is Map &&
                  (e.response!.data as Map).containsKey('message')
              ? e.response!.data['message'].toString()
              : (e.message ?? 'Request failed');

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
}
