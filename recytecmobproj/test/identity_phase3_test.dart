import 'package:flutter_test/flutter_test.dart';
import 'package:recytecmobproj/core/constants/app_constants.dart';
import 'package:recytecmobproj/core/network/api_exceptions.dart';
import 'package:recytecmobproj/data/datasources/auth_api.dart';
import 'package:recytecmobproj/data/models/user_model.dart';

Map<String, dynamic> identityJson({
  required String role,
  Object? profileId = 'profile-1',
}) =>
    {
      '_id': 'user-1',
      'firstName': 'Mobile',
      'lastName': 'User',
      'email': 'mobile@example.com',
      'role': role,
      'status': 'Active',
      'accountStatus': 'active',
      'profileId': profileId,
      'token': 'jwt-token',
      'user': {
        '_id': 'user-1',
        'firstName': 'Mobile',
        'lastName': 'User',
        'email': 'mobile@example.com',
        'role': role,
        'status': 'Active',
      },
    };

void main() {
  group('A-N. canonical role normalization', () {
    const expectedRoles = {
      'household': AppRoles.household,
      'resident': AppRoles.household,
      'user': AppRoles.household,
      'registered_user': AppRoles.household,
      'partner_org': AppRoles.partnerOrg,
      'LGU': AppRoles.partnerOrg,
      'lgu': AppRoles.partnerOrg,
      'Partner Organization': AppRoles.partnerOrg,
      'PartnerOrganization': AppRoles.partnerOrg,
      'collector': AppRoles.collector,
      'Collector': AppRoles.collector,
    };

    for (final entry in expectedRoles.entries) {
      test('${entry.key} becomes ${entry.value}', () {
        expect(AppRoles.canonicalRole(entry.key), entry.value);
        final user = UserModel.fromJson(
          identityJson(role: entry.key),
        );
        expect(user.role, entry.value);
        expect(AppRoles.isCanonical(user.role), isTrue);
      });
    }

    for (final role in ['Staff', 'Admin', 'Super Admin']) {
      test('$role remains unsupported', () {
        expect(AppRoles.canonicalRole(role), isNull);
        expect(AppRoles.shellTargetFor(role), AppShellTarget.accessDenied);
        expect(
          () => UserModel.fromJson(identityJson(role: role)),
          throwsFormatException,
        );
      });
    }
  });

  test('O. profileId remains distinct from the authentication user ID', () {
    final user = UserModel.fromJson(
      identityJson(role: 'household', profileId: 'resident-9'),
    );

    expect(user.id, 'user-1');
    expect(user.profileId, 'resident-9');
    expect(user.profileId, isNot(user.id));
  });

  group('P-R. canonical identities require their profile ID', () {
    for (final role in AppRoles.canonicalMobileRoles) {
      test('$role rejects a missing profileId', () {
        expect(
          () => AuthResponse.fromJson(
            identityJson(role: role, profileId: null),
            requireToken: true,
          ),
          throwsA(isA<ApiException>()),
        );
      });
    }
  });

  test('S. true legacy identity may safely retain a null profileId', () {
    final response = AuthResponse.fromJson(
      identityJson(role: 'Collector', profileId: null),
      requireToken: true,
    );

    expect(response.user.role, AppRoles.collector);
    expect(response.user.profileId, isNull);
    expect(response.user.isLegacyIdentity, isTrue);
  });

  test('T. cached legacy role is canonical after load and serialization', () {
    final loaded = UserModel.fromJson({
      'id': 'cached-user',
      'firstName': 'Cached',
      'lastName': 'Collector',
      'email': 'cached@example.com',
      'role': 'Collector',
      'accountStatus': 'active',
      'profileId': null,
    });
    final migratedCache = loaded.toJson();

    expect(loaded.role, AppRoles.collector);
    expect(migratedCache['role'], AppRoles.collector);
    expect(migratedCache['isLegacyIdentity'], isTrue);
  });

  test('U. display labels stay separate from canonical API roles', () {
    expect(AppRoles.displayNameFor('household'), 'Registered User');
    expect(AppRoles.displayNameFor('partner_org'), 'Partner Organization');
    expect(AppRoles.displayNameFor('collector'), 'Collector');
    expect(AppRoles.canonicalMobileRoles, isNot(contains('Registered User')));
    expect(
      AppRoles.canonicalMobileRoles,
      isNot(contains('Partner Organization')),
    );
  });
}
