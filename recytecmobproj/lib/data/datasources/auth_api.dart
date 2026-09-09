import 'package:dio/dio.dart';

import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_exceptions.dart';
import '../models/user_model.dart';

class AuthResponse {
  final String? token;
  final UserModel user;
  final String? profileId;
  final String accountStatus;

  const AuthResponse({
    this.token,
    required this.user,
    required this.profileId,
    required this.accountStatus,
  });

  factory AuthResponse.fromJson(
    dynamic data, {
    required bool requireToken,
  }) {
    final map = AuthApi.asMap(data);
    final nestedUser = AuthApi.asMap(map['user']);
    final userMap = requireToken
        ? map
        : map.containsKey('_id')
            ? map
            : nestedUser;
    const requiredUserFields = [
      '_id',
      'firstName',
      'lastName',
      'email',
      'role',
      'status',
    ];
    final missingUserField = requiredUserFields.any(
      (key) => (userMap[key] ?? '').toString().trim().isEmpty,
    );
    final hasProfileId = map.containsKey('profileId');
    final accountStatus = (map['accountStatus'] ?? '').toString().trim();
    final token = (map['token'] ?? '').toString().trim();
    final rawRole = (userMap['role'] ?? '').toString();
    final canonicalRole = AppRoles.canonicalRole(rawRole);

    if (missingUserField ||
        !hasProfileId ||
        accountStatus.isEmpty ||
        canonicalRole == null ||
        (requireToken && token.isEmpty)) {
      throw ApiException(
        'Authentication failed because the server returned an incomplete response.',
      );
    }

    final rawProfileId = map['profileId'];
    final profileId =
        rawProfileId == null || rawProfileId.toString().trim().isEmpty
            ? null
            : rawProfileId.toString();
    if (profileId == null && AppRoles.isCanonical(rawRole)) {
      throw ApiException(
        'Authentication failed because the server did not return the required profile identity.',
      );
    }
    final user = UserModel.fromSessionJson({
      ...userMap,
      'accountStatus': accountStatus,
      if (profileId != null) 'profileId': profileId,
    });

    return AuthResponse(
      token: token.isEmpty ? null : token,
      user: user,
      profileId: profileId,
      accountStatus: accountStatus,
    );
  }
}

class RegistrationResponse {
  final String message;
  final UserModel user;
  final String profileId;
  final String accountStatus;

  const RegistrationResponse({
    required this.message,
    required this.user,
    required this.profileId,
    required this.accountStatus,
  });

  factory RegistrationResponse.fromJson(dynamic data) {
    final map = AuthApi.asMap(data);
    final userMap = AuthApi.asMap(map['user']);

    final requiredTopLevelFields = ['message', 'profileId', 'accountStatus'];
    final requiredUserFields = [
      '_id',
      'firstName',
      'lastName',
      'email',
      'role',
      'status',
    ];
    final topLevelMissing = requiredTopLevelFields.any(
      (key) => (map[key] ?? '').toString().trim().isEmpty,
    );
    final userMissing = requiredUserFields.any(
      (key) => (userMap[key] ?? '').toString().trim().isEmpty,
    );

    if (topLevelMissing || userMissing) {
      throw ApiException(
        'Registration failed because the server returned an incomplete response.',
      );
    }

    return RegistrationResponse(
      message: map['message'].toString(),
      user: UserModel.fromSessionJson({
        ...userMap,
        'profileId': map['profileId'],
        'accountStatus': map['accountStatus'],
      }),
      profileId: map['profileId'].toString(),
      accountStatus: map['accountStatus'].toString(),
    );
  }
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

    return AuthResponse.fromJson(res.data, requireToken: true);
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
    final Response res = await _apiClient.dio.post(
      ApiEndpoints.register,
      data: buildRegistrationPayload(
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
      ),
    );

    return RegistrationResponse.fromJson(res.data);
  }

  static Map<String, dynamic> buildRegistrationPayload({
    String? fullName,
    required String email,
    required String password,
    String role = AppRoles.household,
    String? organizationName,
    String? contactPerson,
    String? contactNumber,
    String? phone,
    String? vehicleType,
    String? plateNumber,
  }) {
    final names = splitName(fullName);
    final canonicalRole = AppRoles.canonicalApiRole(role);
    if (canonicalRole == null) {
      throw ArgumentError.value(role, 'role', 'Unsupported public role');
    }
    if (canonicalRole == AppRoles.partnerOrg && !hasValue(organizationName)) {
      throw ArgumentError.value(
        organizationName,
        'organizationName',
        'Organization name is required',
      );
    }
    if (canonicalRole == AppRoles.collector && !hasValue(phone)) {
      throw ArgumentError.value(
        phone,
        'phone',
        'Phone is required for collector registration',
      );
    }
    final canonicalVehicleType = canonicalRole == AppRoles.collector
        ? normalizeVehicleType(vehicleType)
        : null;

    return {
      'firstName': names.first,
      'lastName': names.last,
      'email': email.trim(),
      'password': password,
      'role': canonicalRole,
      if (canonicalRole == AppRoles.household && hasValue(phone))
        'phone': phone!.trim(),
      if (canonicalRole == AppRoles.partnerOrg && hasValue(organizationName))
        'organizationName': organizationName!.trim(),
      if (canonicalRole == AppRoles.partnerOrg && hasValue(contactPerson))
        'contactPerson': contactPerson!.trim(),
      if (canonicalRole == AppRoles.partnerOrg && hasValue(contactNumber))
        'contactNumber': contactNumber!.trim(),
      if (canonicalRole == AppRoles.collector && hasValue(phone))
        'phone': phone!.trim(),
      if (canonicalVehicleType != null) 'vehicleType': canonicalVehicleType,
      if (canonicalRole == AppRoles.collector && hasValue(plateNumber))
        'vehiclePlate': plateNumber!.trim(),
    };
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
    return AuthResponse.fromJson(res.data, requireToken: false);
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
      data: buildLoginPayload(email: email, password: password),
    );
  }

  static Map<String, dynamic> buildLoginPayload({
    required String email,
    required String password,
  }) =>
      {
        'email': email.trim(),
        'password': password,
      };

  static Map<String, dynamic> asMap(dynamic value) {
    if (value is Map) return value.cast<String, dynamic>();
    return <String, dynamic>{};
  }

  Map<String, dynamic> _asMap(dynamic value) => asMap(value);

  String _messageFromMap(Map<String, dynamic> map, {required String fallback}) {
    final message = (map['message'] ?? '').toString().trim();
    return message.isEmpty ? fallback : message;
  }

  static bool hasValue(String? value) =>
      value != null && value.trim().isNotEmpty;

  static String? normalizeVehicleType(String? value) {
    final normalized =
        (value ?? '').trim().toLowerCase().replaceAll(RegExp(r'[ _-]+'), ' ');
    const vehicleTypes = {
      'not assigned': 'Not Assigned',
      'e trike': 'E-Trike',
      'truck': 'Truck',
      'bike': 'Bike',
      'motorcycle': 'Motorcycle',
      'van': 'Van',
    };
    final canonical = vehicleTypes[normalized];
    if (canonical == null) {
      throw ArgumentError.value(
        value,
        'vehicleType',
        'Invalid collector vehicle type',
      );
    }
    return canonical;
  }

  static ({String first, String last}) splitName(String? fullName) {
    final parts = (fullName ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      throw ArgumentError.value(fullName, 'fullName', 'Name is required');
    }

    if (parts.length == 1) {
      throw ArgumentError.value(
        fullName,
        'fullName',
        'First and last name are required',
      );
    }

    return (first: parts.first, last: parts.sublist(1).join(' '));
  }
}
