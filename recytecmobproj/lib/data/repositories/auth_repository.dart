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
    return response.user;
  }

  Future<UserModel?> currentUser() async {
    final token = await _storage.readToken();
    if (token == null || token.isEmpty) return null;

    // The confirmed backend auth routes do not expose /auth/me.
    return null;
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } finally {
      await _storage.clearToken();
    }
  }

  Future<void> _saveTokenIfPresent(String? token) async {
    if (token == null || token.isEmpty) return;
    await _storage.saveToken(token);
  }
}
