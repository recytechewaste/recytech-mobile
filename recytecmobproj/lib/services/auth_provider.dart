import 'package:flutter/material.dart';
import '../core/utils/helpers.dart';
import '../data/repositories/auth_repository.dart';
import '../data/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo;

  AuthProvider(this._repo) {
    _restoreSession();
  }

  UserModel? user;
  bool isLoading = false;
  String? error;
  String? pendingVerificationEmail;

  UserModel? get currentUser => user;

  Future<void> _restoreSession() async {
    isLoading = true;
    notifyListeners();

    try {
      user = await _repo.currentUser();
    } catch (_) {
      user = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      user = await _repo.login(email, password);
      if (user == null) {
        throw StateError('Login response did not include a user profile.');
      }
      pendingVerificationEmail = null;
      return true;
    } catch (e) {
      error = _messageForAuthError(
        e,
        fallback: 'Login failed. Please try again.',
      );
      if (_isEmailVerificationError(error)) {
        pendingVerificationEmail = email.trim();
      }
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<RegistrationResult?> register(
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
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await _repo.register(
        email,
        password,
        fullName: fullName,
        role: role,
        organizationName: organizationName,
        contactPerson: contactPerson,
        contactNumber: contactNumber,
        phone: phone,
        vehicleType: vehicleType,
        plateNumber: plateNumber,
      );
      user = null;
      pendingVerificationEmail =
          result.emailVerificationRequired ? result.email : null;
      return result;
    } catch (e) {
      error = _messageForAuthError(
        e,
        fallback: 'Registration failed. Please try again.',
      );
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await _repo.logout();
    } catch (e) {
      error = _messageForAuthError(
        e,
        fallback: 'Logout failed. Please try again.',
      );
    } finally {
      user = null;
      pendingVerificationEmail = null;
      isLoading = false;
      notifyListeners();
    }
  }

  Future<EmailVerificationResult?> verifyEmail({
    required String email,
    required String pin,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await _repo.verifyEmail(email: email, pin: pin);
      pendingVerificationEmail = null;
      return result;
    } catch (e) {
      error = _messageForAuthError(
        e,
        fallback: 'Email verification failed. Please try again.',
      );
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> resendVerification(String email) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final message = await _repo.resendVerification(email);
      pendingVerificationEmail = email.trim();
      return message;
    } catch (e) {
      error = _messageForAuthError(
        e,
        fallback: 'Could not resend verification PIN. Please try again.',
      );
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String _messageForAuthError(Object exception, {required String fallback}) {
    return userFacingError(exception, fallback: fallback);
  }

  bool _isEmailVerificationError(String? message) {
    final text = (message ?? '').toLowerCase();
    return text.contains('email verification') ||
        text.contains('verify your email') ||
        text.contains('please verify');
  }
}
