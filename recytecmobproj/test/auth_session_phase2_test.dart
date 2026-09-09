import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recytecmobproj/core/constants/app_constants.dart';
import 'package:recytecmobproj/core/network/api_client.dart';
import 'package:recytecmobproj/core/network/api_exceptions.dart';
import 'package:recytecmobproj/core/storage/secure_storage.dart';
import 'package:recytecmobproj/data/datasources/auth_api.dart';
import 'package:recytecmobproj/data/models/user_model.dart';
import 'package:recytecmobproj/data/repositories/auth_repository.dart';

class MemorySecureStorage extends SecureStorage {
  String? token;
  String? userJson;
  int clearCount = 0;

  @override
  Future<void> saveToken(String value) async => token = value;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> saveUserJson(String value) async => userJson = value;

  @override
  Future<String?> readUserJson() async => userJson;

  @override
  Future<void> clearToken() async => token = null;

  @override
  Future<void> clearAuthSession() async {
    token = null;
    userJson = null;
    clearCount += 1;
  }
}

class FakeAuthApi extends AuthApi {
  FakeAuthApi({required this.loginResponse, required this.meResponse});

  AuthResponse loginResponse;
  AuthResponse meResponse;
  Object? loginError;
  Object? meError;
  Object? logoutError;
  int logoutCalls = 0;

  @override
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    if (loginError != null) throw loginError!;
    return loginResponse;
  }

  @override
  Future<AuthResponse> me() async {
    if (meError != null) throw meError!;
    return meResponse;
  }

  @override
  Future<void> logout() async {
    logoutCalls += 1;
    if (logoutError != null) throw logoutError!;
  }
}

UserModel sessionUser({
  String role = AppRoles.household,
  String? profileId = 'profile-1',
  String firstName = 'Current',
}) =>
    UserModel(
      id: 'user-1',
      firstName: firstName,
      lastName: 'User',
      fullName: '$firstName User',
      email: 'current@example.com',
      role: role,
      accountStatus: 'active',
      profileId: profileId,
    );

AuthResponse sessionResponse({
  String? token = 'jwt-token',
  String role = AppRoles.household,
  String? profileId = 'profile-1',
  String firstName = 'Current',
}) =>
    AuthResponse(
      token: token,
      user: sessionUser(
        role: role,
        profileId: profileId,
        firstName: firstName,
      ),
      profileId: profileId,
      accountStatus: 'active',
    );

Map<String, dynamic> authJson({
  String role = AppRoles.household,
  Object? profileId = 'resident-1',
  bool includeToken = true,
}) =>
    {
      '_id': 'user-1',
      'firstName': 'Ada',
      'lastName': 'Lovelace',
      'email': 'ada@example.com',
      'role': role,
      'status': 'Active',
      'profileId': profileId,
      'accountStatus': 'active',
      if (includeToken) 'token': 'signed-jwt',
      'user': {
        '_id': 'user-1',
        'firstName': 'Ada',
        'lastName': 'Lovelace',
        'email': 'ada@example.com',
        'role': role,
        'status': 'Active',
      },
    };

DioException apiFailure(int statusCode, String message) => DioException(
      requestOptions: RequestOptions(path: '/auth/me'),
      response: Response(
        requestOptions: RequestOptions(path: '/auth/me'),
        statusCode: statusCode,
      ),
      type: DioExceptionType.badResponse,
      error: ApiException(message, statusCode: statusCode),
    );

void main() {
  group('Phase 2 login contract', () {
    test('A. request contains email and password only', () {
      expect(
        AuthApi.buildLoginPayload(
          email: ' user@example.com ',
          password: 'Password1!',
        ),
        {
          'email': 'user@example.com',
          'password': 'Password1!',
        },
      );
    });

    test('B-D. response parses actual token, role, and profileId', () {
      final response = AuthResponse.fromJson(
        authJson(role: AppRoles.partnerOrg),
        requireToken: true,
      );

      expect(response.token, 'signed-jwt');
      expect(response.user.role, AppRoles.partnerOrg);
      expect(response.profileId, 'resident-1');
      expect(response.user.profileId, 'resident-1');
      expect(response.accountStatus, 'active');
    });

    test('missing required login fields are contract errors', () {
      for (final key in ['_id', 'role', 'status', 'accountStatus', 'token']) {
        final json = authJson()..remove(key);
        expect(
          () => AuthResponse.fromJson(json, requireToken: true),
          throwsA(isA<ApiException>()),
          reason: key,
        );
      }
    });

    test('login securely caches token and complete identity', () async {
      final storage = MemorySecureStorage();
      final api = FakeAuthApi(
        loginResponse: sessionResponse(),
        meResponse: sessionResponse(token: null),
      );
      final repository = AuthRepository(api: api, storage: storage);

      await repository.login('user@example.com', 'Password1!');

      expect(storage.token, 'jwt-token');
      final cached = jsonDecode(storage.userJson!) as Map<String, dynamic>;
      expect(cached['id'], 'user-1');
      expect(cached['role'], AppRoles.household);
      expect(cached['profileId'], 'profile-1');
      expect(cached['firstName'], 'Current');
      expect(cached['lastName'], 'User');
      expect(cached['email'], 'current@example.com');
      expect(cached['accountStatus'], 'active');
      expect(cached, isNot(contains('password')));
    });
  });

  test('E-G. canonical roles route only to their intended mobile shells', () {
    expect(AppRoles.shellTargetFor('household'), AppShellTarget.household);
    expect(AppRoles.shellTargetFor('partner_org'), AppShellTarget.partnerOrg);
    expect(AppRoles.shellTargetFor('collector'), AppShellTarget.collector);
    expect(AppRoles.shellTargetFor('Staff'), AppShellTarget.accessDenied);
    expect(AppRoles.shellTargetFor('Admin'), AppShellTarget.accessDenied);
  });

  group('Phase 2 session restore', () {
    test('H and K. auth/me refreshes cached identity and profileId', () async {
      final storage = MemorySecureStorage()..token = 'stored-token';
      final api = FakeAuthApi(
        loginResponse: sessionResponse(),
        meResponse: sessionResponse(
          token: null,
          profileId: 'updated-profile',
          firstName: 'Updated',
        ),
      );
      final repository = AuthRepository(api: api, storage: storage);

      final user = await repository.currentUser();

      expect(user!.firstName, 'Updated');
      expect(user.profileId, 'updated-profile');
      expect(storage.token, 'stored-token');
      expect(jsonDecode(storage.userJson!)['profileId'], 'updated-profile');
    });

    test('I-J. auth/me 401 and 403 clear the complete session', () async {
      for (final statusCode in [401, 403]) {
        final storage = MemorySecureStorage()
          ..token = 'stored-token'
          ..userJson = '{}';
        final api = FakeAuthApi(
          loginResponse: sessionResponse(),
          meResponse: sessionResponse(token: null),
        )..meError = apiFailure(
            statusCode,
            statusCode == 403 ? 'Account is inactive.' : 'Not authorized.',
          );
        final repository = AuthRepository(api: api, storage: storage);

        await expectLater(
            repository.currentUser(), throwsA(isA<DioException>()));
        expect(storage.token, isNull);
        expect(storage.userJson, isNull);
      }
    });

    test('temporary auth/me failure does not trust or erase cached identity',
        () async {
      final storage = MemorySecureStorage()
        ..token = 'stored-token'
        ..userJson = '{"id":"cached-user"}';
      final api = FakeAuthApi(
        loginResponse: sessionResponse(),
        meResponse: sessionResponse(token: null),
      )..meError = apiFailure(503, 'Server error. Please try again later.');
      final repository = AuthRepository(api: api, storage: storage);

      await expectLater(repository.currentUser(), throwsA(isA<DioException>()));
      expect(storage.token, 'stored-token');
      expect(storage.userJson, '{"id":"cached-user"}');
    });

    test('L. a legacy null profileId is parsed and cached safely', () async {
      final parsed = AuthResponse.fromJson(
        authJson(role: 'Collector', profileId: null, includeToken: false),
        requireToken: false,
      );
      expect(parsed.profileId, isNull);
      expect(parsed.user.profileId, isNull);
    });
  });

  group('Phase 2 logout and token injection', () {
    test('M-N. logout calls backend and clears local state on success',
        () async {
      final storage = MemorySecureStorage()
        ..token = 'stored-token'
        ..userJson = '{}';
      final api = FakeAuthApi(
        loginResponse: sessionResponse(),
        meResponse: sessionResponse(token: null),
      );
      final repository = AuthRepository(api: api, storage: storage);

      await repository.logout();

      expect(api.logoutCalls, 1);
      expect(storage.token, isNull);
      expect(storage.userJson, isNull);
    });

    test('O-P. logout clears token even when backend call fails', () async {
      final storage = MemorySecureStorage()
        ..token = 'stored-token'
        ..userJson = '{}';
      final api = FakeAuthApi(
        loginResponse: sessionResponse(),
        meResponse: sessionResponse(token: null),
      )..logoutError = Exception('offline');
      final repository = AuthRepository(api: api, storage: storage);

      await expectLater(repository.logout(), throwsException);

      expect(api.logoutCalls, 1);
      expect(storage.token, isNull);
      expect(storage.userJson, isNull);
    });

    test('Bearer token is attached once and absent after logout', () async {
      final storage = MemorySecureStorage()..token = 'stored-token';
      final client = ApiClient(dio: Dio(), storage: storage);
      final request = RequestOptions(path: '/auth/me');

      await client.attachAuthorizationHeader(request);
      expect(request.headers['Authorization'], 'Bearer stored-token');

      request.headers['Authorization'] = 'Bearer explicit-token';
      await client.attachAuthorizationHeader(request);
      expect(request.headers['Authorization'], 'Bearer explicit-token');

      await storage.clearAuthSession();
      final afterLogout = RequestOptions(path: '/auth/me');
      await client.attachAuthorizationHeader(afterLogout);
      expect(afterLogout.headers, isNot(contains('Authorization')));
    });
  });
}
