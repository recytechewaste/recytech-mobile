import 'dart:convert';

import '../../core/storage/secure_storage.dart';
import '../datasources/auth_api.dart';
import '../models/user_model.dart';

class RegistrationResult {
  const RegistrationResult({
    required this.email,
    required this.message,
    required this.role,
    required this.accountStatus,
    required this.emailVerificationRequired,
    required this.emailSent,
  });

  final String email;
  final String message;
  final String role;
  final String accountStatus;
  final bool emailVerificationRequired;
  final bool emailSent;
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

    await _saveTokenIfPresent(response.token);
    await _saveUserIfPresent(response.user);
    if (response.user == null) {
      await _storage.clearAuthSession();
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
      email: response.email,
      message: response.message,
      role: response.role,
      accountStatus: response.accountStatus,
      emailVerificationRequired: response.emailVerificationRequired,
      emailSent: response.emailSent,
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
      final response = await _api.me();
      await _saveTokenIfPresent(response.token);
      await _saveUserIfPresent(response.user);
      if (response.user != null) return response.user;
    } catch (_) {
      await _storage.clearAuthSession();
    }
    return null;
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

  Future<void> _saveTokenIfPresent(String? token) async {
    if (token == null || token.isEmpty) return;
    await _storage.saveToken(token);
  }

  Future<void> _saveUserIfPresent(UserModel? user) async {
    if (user == null) return;
    await _storage.saveUserJson(jsonEncode(user.toJson()));
  }

  String _messageFromResponse(
    Map<String, dynamic> response, {
    required String fallback,
  }) {
    final message = (response['message'] ?? '').toString().trim();
    return message.isEmpty ? fallback : message;
  }
}
