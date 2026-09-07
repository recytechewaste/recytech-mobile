import 'package:dio/dio.dart';

import '../../core/constants/app_constants.dart';
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

class RegistrationResponse {
  final String message;
  final String email;
  final String role;
  final String accountStatus;
  final bool emailVerificationRequired;
  final bool emailSent;

  const RegistrationResponse({
    required this.message,
    required this.email,
    required this.role,
    required this.accountStatus,
    required this.emailVerificationRequired,
    required this.emailSent,
  });
}

class EmailVerificationResponse {
  final String message;
  final String accountStatus;
  final UserModel? user;

  const EmailVerificationResponse({
    required this.message,
    required this.accountStatus,
    this.user,
  });
}

class AuthApi {
  final ApiClient _apiClient;

  AuthApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final Response res = await _postLogin(
      email: email,
      password: password,
    );

    return _parseAuthResponse(res.data);
  }

  Future<RegistrationResponse> register({
    String? fullName,
    required String email,
    required String password,
    String role = 'household',
    String? organizationName,
    String? contactPerson,
    String? contactNumber,
    String? phone,
    String? vehicleType,
    String? plateNumber,
  }) async {
    final names = _splitName(fullName);
    final canonicalRole = AppRoles.canonicalApiRole(role) ?? role;

    final Response res = await _apiClient.dio.post(
      ApiEndpoints.register,
      data: {
        'firstName': names.first,
        'lastName': names.last,
        'fullName': fullName,
        'email': email,
        'password': password,
        'role': canonicalRole,
        if (_hasValue(organizationName)) 'organizationName': organizationName,
        if (_hasValue(contactPerson)) 'contactPerson': contactPerson,
        if (_hasValue(contactNumber)) 'contactNumber': contactNumber,
        if (_hasValue(phone)) 'phone': phone,
        if (_hasValue(vehicleType)) 'vehicleType': vehicleType,
        if (_hasValue(plateNumber)) 'vehiclePlate': plateNumber,
      },
    );

    final map = _asMap(res.data);
    return RegistrationResponse(
      message: _messageFromMap(
        map,
        fallback: 'Registration successful. You can now log in.',
      ),
      email: (map['email'] ?? email).toString(),
      role: (map['role'] ?? canonicalRole).toString(),
      accountStatus: (map['accountStatus'] ?? 'active').toString(),
      emailVerificationRequired: map['emailVerificationRequired'] == true,
      emailSent: map['emailSent'] == true,
    );
  }

  Future<EmailVerificationResponse> verifyEmail({
    required String email,
    required String pin,
  }) async {
    final Response res = await _apiClient.dio.post(
      ApiEndpoints.verifyEmail,
      data: {
        'email': email,
        'pin': pin,
      },
    );

    final map = _asMap(res.data);
    return EmailVerificationResponse(
      message: _messageFromMap(
        map,
        fallback: 'Email verified successfully. You can now log in.',
      ),
      accountStatus: (map['accountStatus'] ??
              _asMap(map['user'])['accountStatus'] ??
              'active')
          .toString(),
      user: _parseUser(map),
    );
  }

  Future<AuthResponse> me() async {
    final Response res = await _apiClient.dio.get(ApiEndpoints.me);
    return _parseAuthResponse(res.data);
  }

  Future<Map<String, dynamic>> resendVerification({
    required String email,
  }) async {
    final Response res = await _apiClient.dio.post(
      ApiEndpoints.resendVerification,
      data: {'email': email},
    );

    return _asMap(res.data);
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
  }) {
    return _apiClient.dio.post(
      ApiEndpoints.login,
      data: {
        'email': email,
        'password': password,
      },
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) return value.cast<String, dynamic>();
    return <String, dynamic>{};
  }

  String _messageFromMap(Map<String, dynamic> map, {required String fallback}) {
    final message = (map['message'] ?? '').toString().trim();
    return message.isEmpty ? fallback : message;
  }

  bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;

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
