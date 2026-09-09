import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/network/api_exceptions.dart';
import '../../core/storage/secure_storage.dart';
import '../datasources/auth_api.dart';
import '../models/user_model.dart';

class RegistrationResult {
  const RegistrationResult({
    required this.message,
    required this.user,
    required this.profileId,
    required this.accountStatus,
  });

  final String message;
  final UserModel user;
  final String profileId;
  final String accountStatus;
}

class EmailVerificationResult {
  const EmailVerificationResult({
    required this.message,
    required this.accountStatus,
    this.user,
  });

  final String message;
  final String accountStatus;
  final UserModel? user;
}

class AuthRepository {
  final AuthApi _api;
  final SecureStorage _storage;

  AuthRepository({
    AuthApi? api,
    SecureStorage? storage,
  })  : _api = api ?? AuthApi(),
        _storage = storage ?? SecureStorage();

  Future<UserModel?> login(String email, String password) async {
    final response = await _api.login(
      email: email,
      password: password,
    );

    final token = response.token;
    if (token == null || token.isEmpty) {
      throw ApiException(
        'Authentication failed because the server returned an incomplete response.',
      );
    }
    try {
      await _storage.saveToken(token);
      await _saveUser(response.user);
    } catch (_) {
      await _storage.clearAuthSession();
      rethrow;
    }
    return response.user;
  }

  Future<RegistrationResult> register(
    String email,
    String password, {
    String? fullName,
    String role = 'household',
    String? organizationName,
    String? contactPerson,
    String? contactNumber,
    String? phone,
    String? vehicleType,
    String? plateNumber,
  }) async {
    final response = await _api.register(
      fullName: fullName,
      email: email,
      password: password,
      role: role,
      organizationName: organizationName,
      contactPerson: contactPerson,
      contactNumber: contactNumber,
      phone: phone,
      vehicleType: vehicleType,
      plateNumber: plateNumber,
    );

    await _storage.clearAuthSession();
    return RegistrationResult(
      message: response.message,
      user: response.user,
      profileId: response.profileId,
      accountStatus: response.accountStatus,
    );
  }

  Future<EmailVerificationResult> verifyEmail({
    required String email,
    required String pin,
  }) async {
    final response = await _api.verifyEmail(email: email, pin: pin);
    return EmailVerificationResult(
      message: response.message,
      accountStatus: response.accountStatus,
      user: response.user,
    );
  }

  Future<String> resendVerification(String email) async {
    final response = await _api.resendVerification(email: email);
    return _messageFromResponse(
      response,
      fallback: 'A new verification PIN has been sent.',
    );
  }

  Future<UserModel?> currentUser() async {
    final token = await _storage.readToken();
    if (token == null || token.isEmpty) return null;

    try {
      await _migrateCachedIdentity();
      final response = await _api.me();
      await _saveUser(response.user);
      return response.user;
    } catch (error) {
      final statusCode = _statusCode(error);
      if (statusCode == 401 || statusCode == 403 || error is ApiException) {
        await _storage.clearAuthSession();
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } finally {
      await _storage.clearAuthSession();
    }
  }

  Future<String> forgotPassword(String email) async {
    final response = await _api.forgotPassword(email: email);
    return _messageFromResponse(
      response,
      fallback: 'If the email exists, a PIN has been sent.',
    );
  }

  Future<String> verifyResetPin({
    required String email,
    required String pin,
  }) async {
    final response = await _api.verifyPin(email: email, pin: pin);
    final token = response['resetToken'] ?? response['token'];
    final tokenText = (token ?? '').toString().trim();
    if (tokenText.isEmpty) {
      throw StateError('PIN was verified, but no reset token was returned.');
    }
    return tokenText;
  }

  Future<String> resetPassword({
    required String email,
    required String newPassword,
    required String confirmPassword,
    required String resetToken,
  }) async {
    final response = await _api.resetPassword(
      email: email,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
      resetToken: resetToken,
    );
    return _messageFromResponse(
      response,
      fallback: 'Password has been reset successfully.',
    );
  }

  Future<void> _saveUser(UserModel user) async {
    await _storage.saveUserJson(jsonEncode(user.toJson()));
  }

  Future<void> _migrateCachedIdentity() async {
    final cachedJson = await _storage.readUserJson();
    if (cachedJson == null || cachedJson.trim().isEmpty) return;

    try {
      final decoded = jsonDecode(cachedJson);
      if (decoded is! Map) return;
      final user = UserModel.fromSessionJson(decoded.cast<String, dynamic>());
      await _saveUser(user);
    } on FormatException {
      // The server remains authoritative. /auth/me will refresh or reject it.
    }
  }

  int? _statusCode(Object error) {
    if (error is ApiException) return error.statusCode;
    if (error is DioException && error.error is ApiException) {
      return (error.error as ApiException).statusCode;
    }
    return null;
  }

  String _messageFromResponse(
    Map<String, dynamic> response, {
    required String fallback,
  }) {
    final message = (response['message'] ?? '').toString().trim();
    return message.isEmpty ? fallback : message;
  }
}
