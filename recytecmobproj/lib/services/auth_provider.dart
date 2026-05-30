import 'package:flutter/material.dart';

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
      return true;
    } catch (e) {
      error = _messageForAuthError(
        e,
        fallback: 'Login failed. Please try again.',
      );
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(
    String email,
    String password, {
    String? fullName,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      user = await _repo.register(
        email,
        password,
        fullName: fullName,
      );
      return true;
    } catch (e) {
      error = _messageForAuthError(
        e,
        fallback: 'Registration failed. Please try again.',
      );
      return false;
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
      isLoading = false;
      notifyListeners();
    }
  }

  String _messageForAuthError(Object exception, {required String fallback}) {
    final text = exception.toString();
    const marker = 'message: ';
    if (text.contains(marker)) {
      return text.split(marker).last.replaceAll(')', '').trim();
    }

    return fallback;
  }
}
