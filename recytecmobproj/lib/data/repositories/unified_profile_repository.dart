import 'package:dio/dio.dart';

import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_exceptions.dart';
import '../models/unified_profile_model.dart';

class UnifiedProfileApi {
  UnifiedProfileApi({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> fetchProfile() async {
    final response = await _apiClient.dio.get(ApiEndpoints.userProfile);
    return _map(response.data);
  }

  Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> fields) async {
    final response = await _apiClient.dio.put(
      ApiEndpoints.userProfile,
      data: fields,
      options: Options(contentType: Headers.jsonContentType),
    );
    return _map(response.data);
  }

  Future<Map<String, dynamic>> changePassword(
      Map<String, dynamic> fields) async {
    final response = await _apiClient.dio.put(
      ApiEndpoints.changePassword,
      data: fields,
      options: Options(contentType: Headers.jsonContentType),
    );
    return _map(response.data);
  }

  Map<String, dynamic> _map(dynamic value) =>
      value is Map ? value.cast<String, dynamic>() : <String, dynamic>{};
}

class UnifiedProfileRepository {
  UnifiedProfileRepository({UnifiedProfileApi? api})
      : _api = api ?? UnifiedProfileApi();

  static const vehicleTypes = <String>{
    'Motorcycle',
    'Van',
    'Truck',
    'E-Trike',
    'Bike',
    'Other',
  };

  final UnifiedProfileApi _api;

  Future<UnifiedProfile> fetchProfile() async {
    try {
      return UnifiedProfile.fromJson(await _api.fetchProfile());
    } catch (error) {
      throw _mapError(error, 'Unable to load your profile.');
    }
  }

  Future<UnifiedProfile> updateProfile({
    required String role,
    required Map<String, dynamic> draft,
  }) async {
    final fields = buildProfilePayload(role: role, draft: draft);
    try {
      return UnifiedProfile.fromJson(await _api.updateProfile(fields));
    } catch (error) {
      throw _mapError(error, 'Unable to update your profile.');
    }
  }

  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final validation = validatePassword(currentPassword, newPassword);
    if (validation != null) throw UnifiedProfileException(validation);
    try {
      final response = await _api.changePassword({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
      return _safeMessage(response['message']) ??
          'Password updated successfully';
    } catch (error) {
      throw _mapError(error, 'Unable to update your password.');
    }
  }

  static Map<String, dynamic> buildProfilePayload({
    required String role,
    required Map<String, dynamic> draft,
  }) {
    final canonicalRole = AppRoles.canonicalRole(role);
    if (canonicalRole == null) {
      throw const UnifiedProfileException('Unsupported mobile profile role.');
    }
    final allowed = switch (canonicalRole) {
      AppRoles.household => const {'firstName', 'lastName', 'phone', 'address'},
      AppRoles.partnerOrg => const {
          'firstName',
          'lastName',
          'organizationName',
          'contactPerson',
          'contactNumber',
          'address',
        },
      AppRoles.collector => const {
          'firstName',
          'lastName',
          'phone',
          'vehicleType',
          'vehiclePlate',
        },
      _ => const <String>{},
    };
    final payload = <String, dynamic>{};
    for (final key in allowed) {
      if (draft.containsKey(key)) payload[key] = draft[key].toString().trim();
    }
    _validateProfile(canonicalRole, payload);
    return payload;
  }

  static String? validatePassword(String currentPassword, String newPassword) {
    if (currentPassword.isEmpty) return 'Current password is required';
    if (newPassword.isEmpty) return 'New password is required';
    final valid = newPassword.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(newPassword) &&
        RegExp(r'[a-z]').hasMatch(newPassword) &&
        RegExp(r'[0-9]').hasMatch(newPassword) &&
        RegExp(r'[@$!%*?&]').hasMatch(newPassword);
    return valid
        ? null
        : 'New password must be at least 8 characters long and contain uppercase, lowercase, a number, and one of @, \$, !, %, *, ?, or &.';
  }

  static void _validateProfile(String role, Map<String, dynamic> fields) {
    final namePattern = RegExp(r'^[A-Za-z -]{2,50}$');
    for (final key in const ['firstName', 'lastName']) {
      if (!namePattern.hasMatch((fields[key] ?? '').toString())) {
        throw UnifiedProfileException(
          '${key == 'firstName' ? 'First' : 'Last'} name must be between 2 and 50 characters and use letters, spaces, or hyphens.',
        );
      }
    }
    final phoneKey = role == AppRoles.partnerOrg ? 'contactNumber' : 'phone';
    final phone = (fields[phoneKey] ?? '').toString();
    if (phone.isNotEmpty && !RegExp(r'^[0-9+-]{7,20}$').hasMatch(phone)) {
      throw const UnifiedProfileException(
        'Phone number must be 7 to 20 characters using digits, plus, or hyphens.',
      );
    }
    if (role == AppRoles.partnerOrg &&
        (fields['organizationName'] ?? '').toString().length < 2) {
      throw const UnifiedProfileException(
        'Organization name must be at least 2 characters.',
      );
    }
    if (role == AppRoles.collector) {
      final vehicleType = (fields['vehicleType'] ?? '').toString();
      if (!vehicleTypes.contains(vehicleType)) {
        throw const UnifiedProfileException('Invalid vehicle type');
      }
      final plate = (fields['vehiclePlate'] ?? '').toString();
      if (plate.isNotEmpty && !RegExp(r'^[A-Za-z0-9 -]+$').hasMatch(plate)) {
        throw const UnifiedProfileException(
          'Vehicle plate may use letters, numbers, spaces, and dashes.',
        );
      }
    }
  }

  UnifiedProfileException _mapError(Object error, String fallback) {
    if (error is UnifiedProfileException) return error;
    if (error is DioException) {
      final safeResponse = _safeMessage(_responseMessage(error.response?.data));
      if (safeResponse != null) return UnifiedProfileException(safeResponse);
      final apiError = error.error;
      if (apiError is ApiException) {
        final safeApiMessage = _safeMessage(apiError.message);
        if (safeApiMessage != null) {
          return UnifiedProfileException(safeApiMessage);
        }
      }
      switch (error.response?.statusCode) {
        case 401:
          return const UnifiedProfileException(
            'Your session has expired. Please sign in again.',
          );
        case 404:
          return const UnifiedProfileException('User not found');
      }
    }
    return UnifiedProfileException(fallback);
  }

  static dynamic _responseMessage(dynamic value) {
    if (value is Map) return value['message'];
    return null;
  }

  static String? _safeMessage(dynamic value) {
    final message = (value ?? '').toString().trim();
    final lowered = message.toLowerCase();
    if (message.isEmpty ||
        message.length > 220 ||
        lowered.contains('<html') ||
        lowered.contains('dioexception') ||
        lowered.contains('mongodb') ||
        lowered.contains('/users/')) {
      return null;
    }
    return message;
  }
}

class UnifiedProfileException implements Exception {
  const UnifiedProfileException(this.message);

  final String message;

  @override
  String toString() => message;
}
