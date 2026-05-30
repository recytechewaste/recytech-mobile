import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/user_model.dart';

class AuthResponse {
  final String? token;
  final UserModel? user;

  const AuthResponse({
    this.token,
    this.user,
  });
}

class AuthApi {
  final ApiClient _apiClient;

  AuthApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<AuthResponse> login({
    required String email,
    required String password,
    String role = 'Staff',
  }) async {
    try {
      final Response res = await _postLogin(
        email: email,
        password: password,
        role: role,
      );

      return _parseAuthResponse(res.data);
    } on DioException catch (e) {
      if (role == 'Staff' && _isCollectorRoleMismatch(e)) {
        final Response retry = await _postLogin(
          email: email,
          password: password,
          role: 'Collector',
        );

        return _parseAuthResponse(retry.data);
      }

      rethrow;
    }
  }

  Future<AuthResponse> register({
    String? fullName,
    required String email,
    required String password,
    String role = 'Staff',
  }) async {
    final names = _splitName(fullName);

    final Response res = await _apiClient.dio.post(
      ApiEndpoints.register,
      data: {
        'firstName': names.first,
        'lastName': names.last,
        'email': email,
        'password': password,
        'role': role,
      },
    );

    return _parseAuthResponse(res.data);
  }

  Future<void> logout() async {
    await _apiClient.dio.post(ApiEndpoints.logout);
  }

  Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    final Response res = await _apiClient.dio.post(
      ApiEndpoints.forgotPassword,
      data: {'email': email},
    );

    return _asMap(res.data);
  }

  Future<Map<String, dynamic>> verifyPin({
    required String email,
    required String pin,
  }) async {
    final Response res = await _apiClient.dio.post(
      ApiEndpoints.verifyPin,
      data: {
        'email': email,
        'pin': pin,
      },
    );

    return _asMap(res.data);
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String newPassword,
    required String confirmPassword,
    required String resetToken,
  }) async {
    final Response res = await _apiClient.dio.post(
      ApiEndpoints.resetPassword,
      data: {
        'email': email,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
        'resetToken': resetToken,
      },
    );

    return _asMap(res.data);
  }

  AuthResponse _parseAuthResponse(dynamic data) {
    final map = _asMap(data);
    return AuthResponse(
      token: _extractToken(map),
      user: _parseUser(map),
    );
  }

  String? _extractToken(Map<String, dynamic> map) {
    final token = map['token'] ??
        map['accessToken'] ??
        map['jwt'] ??
        _asMap(map['data'])['token'] ??
        _asMap(map['data'])['accessToken'];

    return token?.toString();
  }

  UserModel? _parseUser(dynamic data) {
    final map = _asMap(data);
    final dataMap = _asMap(map['data']);
    final userMap = _asMap(
      map['user'] ??
          dataMap['user'] ??
          dataMap['account'] ??
          map['account'] ??
          map['profile'],
    );

    if (userMap.isEmpty && (map.containsKey('_id') || map.containsKey('id'))) {
      return UserModel.fromJson(map);
    }

    if (userMap.isEmpty) return null;
    return UserModel.fromJson(userMap);
  }

  Future<Response> _postLogin({
    required String email,
    required String password,
    required String role,
  }) {
    return _apiClient.dio.post(
      ApiEndpoints.login,
      data: {
        'email': email,
        'password': password,
        'role': role,
      },
    );
  }

  bool _isCollectorRoleMismatch(DioException exception) {
    final message = [
      exception.error,
      exception.response?.data,
      exception.message,
    ].join(' ').toLowerCase();

    return message.contains('registered as collector') ||
        (message.contains('collector') && message.contains('not staff'));
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) return value.cast<String, dynamic>();
    return <String, dynamic>{};
  }

  ({String first, String last}) _splitName(String? fullName) {
    final parts = (fullName ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return (first: 'Mobile', last: 'User');
    }

    if (parts.length == 1) {
      return (first: parts.first, last: 'User');
    }

    return (first: parts.first, last: parts.sublist(1).join(' '));
  }
}
