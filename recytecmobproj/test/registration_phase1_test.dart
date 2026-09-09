import 'package:flutter_test/flutter_test.dart';
import 'package:recytecmobproj/core/config/env.dart';
import 'package:recytecmobproj/core/constants/app_constants.dart';
import 'package:recytecmobproj/core/network/api_client.dart';
import 'package:recytecmobproj/core/network/api_endpoints.dart';
import 'package:recytecmobproj/core/network/api_exceptions.dart';
import 'package:recytecmobproj/core/utils/validators.dart';
import 'package:recytecmobproj/data/datasources/auth_api.dart';

void main() {
  group('Phase 1 registration payloads', () {
    test('builds the household payload without synthetic fields', () {
      final payload = AuthApi.buildRegistrationPayload(
        fullName: 'Ada Lovelace',
        email: ' ada@example.com ',
        password: 'Secure1!',
        role: AppRoles.household,
        phone: ' 09171234567 ',
        organizationName: 'Ignored Organization',
      );

      expect(payload, {
        'firstName': 'Ada',
        'lastName': 'Lovelace',
        'email': 'ada@example.com',
        'password': 'Secure1!',
        'role': AppRoles.household,
        'phone': '09171234567',
      });
      expect(payload, isNot(contains('fullName')));
      expect(payload, isNot(contains('accountStatus')));
    });

    test('builds the partner organization payload', () {
      final payload = AuthApi.buildRegistrationPayload(
        fullName: 'Grace Hopper',
        email: 'grace@example.com',
        password: 'Secure1!',
        role: 'Partner Organization',
        organizationName: ' RecyTech Partner ',
        contactPerson: ' Grace Hopper ',
        contactNumber: ' 09181234567 ',
      );

      expect(payload, {
        'firstName': 'Grace',
        'lastName': 'Hopper',
        'email': 'grace@example.com',
        'password': 'Secure1!',
        'role': AppRoles.partnerOrg,
        'organizationName': 'RecyTech Partner',
        'contactPerson': 'Grace Hopper',
        'contactNumber': '09181234567',
      });
    });

    test('builds the collector payload and canonicalizes vehicle type', () {
      final payload = AuthApi.buildRegistrationPayload(
        fullName: 'Juan Dela Cruz',
        email: 'juan@example.com',
        password: 'Secure1!',
        role: 'Collector',
        phone: '09191234567',
        vehicleType: 'e_trike',
        plateNumber: ' ABC 123 ',
        contactNumber: 'not-sent',
      );

      expect(payload, {
        'firstName': 'Juan',
        'lastName': 'Dela Cruz',
        'email': 'juan@example.com',
        'password': 'Secure1!',
        'role': AppRoles.collector,
        'phone': '09191234567',
        'vehicleType': 'E-Trike',
        'vehiclePlate': 'ABC 123',
      });
    });

    test('rejects missing partner organization name', () {
      expect(
        () => AuthApi.buildRegistrationPayload(
          fullName: 'Grace Hopper',
          email: 'grace@example.com',
          password: 'Secure1!',
          role: AppRoles.partnerOrg,
        ),
        throwsArgumentError,
      );
    });

    test('rejects missing collector phone and invalid vehicle type', () {
      expect(
        () => AuthApi.buildRegistrationPayload(
          fullName: 'Juan Cruz',
          email: 'juan@example.com',
          password: 'Secure1!',
          role: AppRoles.collector,
          vehicleType: 'Truck',
        ),
        throwsArgumentError,
      );
      expect(
        () => AuthApi.buildRegistrationPayload(
          fullName: 'Juan Cruz',
          email: 'juan@example.com',
          password: 'Secure1!',
          role: AppRoles.collector,
          phone: '09191234567',
          vehicleType: 'Hovercraft',
        ),
        throwsArgumentError,
      );
    });

    test('always emits one of the three canonical public roles', () {
      expect(
        AppRoles.canonicalApiRole('registered_user'),
        AppRoles.household,
      );
      expect(
        AppRoles.canonicalApiRole('Partner Organization'),
        AppRoles.partnerOrg,
      );
      expect(AppRoles.canonicalApiRole('Collector'), AppRoles.collector);
      expect(AppRoles.canonicalApiRole('Admin'), isNull);
    });
  });

  group('Phase 1 registration response', () {
    final responseJson = {
      'message': 'Registration successful.',
      'user': {
        '_id': 'user-1',
        'firstName': 'Ada',
        'lastName': 'Lovelace',
        'email': 'ada@example.com',
        'role': 'household',
        'status': 'Active',
      },
      'profileId': 'resident-1',
      'accountStatus': 'active',
    };

    test('parses actual user, profileId, and accountStatus without a token',
        () {
      final response = RegistrationResponse.fromJson(responseJson);

      expect(response.message, 'Registration successful.');
      expect(response.user.id, 'user-1');
      expect(response.user.role, 'household');
      expect(response.user.accountStatus, 'active');
      expect(response.profileId, 'resident-1');
      expect(response.accountStatus, 'active');
      expect(responseJson, isNot(contains('token')));
    });

    test('treats missing contract fields as an error', () {
      final incomplete = Map<String, dynamic>.from(responseJson)
        ..remove('profileId');
      expect(
        () => RegistrationResponse.fromJson(incomplete),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('Phase 1 validation and errors', () {
    test('requires the complete web password policy', () {
      expect(registrationPasswordError('short'), isNotNull);
      expect(registrationPasswordError('lowercase1!'), isNotNull);
      expect(registrationPasswordError('UPPERCASE1!'), isNotNull);
      expect(registrationPasswordError('NoNumber!'), isNotNull);
      expect(registrationPasswordError('NoSpecial1'), isNotNull);
      expect(registrationPasswordError('ValidPass1!'), isNull);
    });

    test('prefers the first validation error and supports known 400 messages',
        () {
      expect(
        ApiClient.responseErrorMessage({
          'message': 'Password validation failed.',
          'errors': [
            {'msg': 'Password must include a special character.'},
          ],
        }),
        'Password must include a special character.',
      );

      for (final message in [
        'An account or profile with this email already exists.',
        'Organization name is required for partner organization registration.',
        'Phone or contact number is required for collector registration.',
        'Invalid vehicle type. Allowed values are Not Assigned, E-Trike, Truck, Bike, Motorcycle, and Van.',
      ]) {
        expect(ApiClient.responseErrorMessage({'message': message}), message);
      }
    });
  });

  test('production registration URL contains exactly one /api segment', () {
    expect(Env.baseUrl, 'https://recytech-web.onrender.com/api');
    const url = '${Env.baseUrl}${ApiEndpoints.register}';
    expect(url, 'https://recytech-web.onrender.com/api/auth/register');
    expect(RegExp(r'/api').allMatches(url), hasLength(1));
  });
}
