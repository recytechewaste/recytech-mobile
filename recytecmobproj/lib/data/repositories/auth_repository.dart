import 'dart:convert';

import '../../core/storage/secure_storage.dart';
import '../datasources/auth_api.dart';
import '../models/user_model.dart';

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

  Future<UserModel?> register(
    String email,
    String password, {
    String? fullName,
  }) async {
    final response = await _api.register(
      fullName: fullName,
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

  Future<UserModel?> currentUser() async {
    final token = await _storage.readToken();
    if (token == null || token.isEmpty) return null;

    // The confirmed backend auth routes do not expose /auth/me.
    final userJson = await _storage.readUserJson();
    if (userJson == null || userJson.isEmpty) {
      await _storage.clearAuthSession();
      return null;
    }

    try {
      final decoded = jsonDecode(userJson);
      if (decoded is! Map) {
        await _storage.clearAuthSession();
        return null;
      }

      return UserModel.fromJson(decoded.cast<String, dynamic>());
    } catch (_) {
      await _storage.clearAuthSession();
      return null;
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
