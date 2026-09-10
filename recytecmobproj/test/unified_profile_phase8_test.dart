import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recytecmobproj/core/constants/app_constants.dart';
import 'package:recytecmobproj/core/network/api_client.dart';
import 'package:recytecmobproj/core/network/api_endpoints.dart';
import 'package:recytecmobproj/data/models/collector_profile_model.dart';
import 'package:recytecmobproj/data/models/unified_profile_model.dart';
import 'package:recytecmobproj/data/repositories/collector_repository.dart';
import 'package:recytecmobproj/data/repositories/unified_profile_repository.dart';
import 'package:recytecmobproj/presentation/profile/unified_profile_screen.dart';

void main() {
  group('unified profile parsing', () {
    test('parses identity without mixing user and profile IDs', () {
      final profile = UnifiedProfile.fromJson(_profile('household'));
      expect(profile.userId, 'user-1');
      expect(profile.profileId, 'profile-1');
      expect(profile.role, AppRoles.household);
      expect(profile.linkedProfileFields['phone'], '+639170000000');
      expect(profile.accountStatus, 'active');
    });

    test('parses PartnerOrganization and Collector fields', () {
      final partner = UnifiedProfile.fromJson(_profile('partner_org'));
      final collector = UnifiedProfile.fromJson(_profile('collector'));
      expect(partner.roleLabel, 'Partner Organization');
      expect(partner.linkedProfileFields['organizationName'], 'RecyTech Org');
      expect(collector.roleLabel, 'Collector');
      expect(collector.linkedProfileFields['vehicleType'], 'Truck');
    });

    test('selects backend-owned names independently of role labels', () {
      expect(
        UnifiedProfile.fromJson(_profile('household')).identityName,
        'Maria Santos-Cruz',
      );
      expect(
        UnifiedProfile.fromJson(_profile('partner_org')).identityName,
        'RecyTech Org',
      );
      expect(
        UnifiedProfile.fromJson(_profile('collector')).identityName,
        'Maria Santos-Cruz',
      );

      final productionPartnerShape = UnifiedProfile.fromJson({
        ..._profile('partner_org'),
        'profile': {
          '_id': 'profile-1',
          'name': 'Green Municipality',
        },
      });
      expect(productionPartnerShape.identityName, 'Green Municipality');
    });

    test('does not promote role labels to persisted profile identity', () {
      for (final entry in {
        AppRoles.household: 'Registered User',
        AppRoles.partnerOrg: 'Partner Organization',
        AppRoles.collector: 'Collector',
      }.entries) {
        final profile = UnifiedProfile.fromJson({
          'user': {
            '_id': 'user-1',
            'email': 'actor@recytech.com',
            'role': entry.key,
            'name': entry.value,
            'fullName': entry.value,
          },
          'profile': {
            '_id': 'profile-1',
            'name': entry.value,
            'organizationName': entry.value,
            'fullName': entry.value,
          },
        });

        expect(profile.identityName, isNull, reason: entry.key);
      }
    });

    test('unsupported Web roles cannot become mobile profiles', () {
      expect(
        () => UnifiedProfile.fromJson(_profile('admin')),
        throwsFormatException,
      );
    });
  });

  group('profile identity UI', () {
    for (final entry in {
      AppRoles.household: ('Maria Santos-Cruz', 'Registered User'),
      AppRoles.partnerOrg: ('RecyTech Org', 'Partner Organization'),
      AppRoles.collector: ('Maria Santos-Cruz', 'Collector'),
    }.entries) {
      testWidgets('${entry.key} renders actual name above its role label',
          (tester) async {
        await _pumpProfile(
            tester, UnifiedProfile.fromJson(_profile(entry.key)));

        final name = tester.widget<Text>(
          find.byKey(const Key('profile-display-name')),
        );
        final role = tester.widget<Text>(
          find.byKey(const Key('profile-role-label')),
        );
        expect(name.data, entry.value.$1);
        expect(role.data, entry.value.$2);
        expect(name.data, isNot(role.data));
      });
    }

    testWidgets('missing backend name uses a render-only neutral fallback',
        (tester) async {
      final profile = UnifiedProfile.fromJson({
        'user': {
          '_id': 'user-1',
          'email': 'household@recytech.com',
          'role': AppRoles.household,
        },
        'profile': {'_id': 'profile-1'},
      });

      await _pumpProfile(tester, profile);

      expect(
        tester.widget<Text>(find.byKey(const Key('profile-display-name'))).data,
        'Name unavailable',
      );
      expect(profile.identityName, isNull);
    });

    testWidgets('shows curated Household details without internal identifiers',
        (tester) async {
      await _pumpProfile(
        tester,
        UnifiedProfile.fromJson({
          ..._profile(AppRoles.household),
          'profile': {
            ...(_profile(AppRoles.household)['profile'] as Map),
            'pointsBalance': 80,
            'privateNotes': 'never render this',
          },
        }),
      );

      expect(find.text('Account details'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Phone'), findsOneWidget);
      expect(find.text('Address'), findsOneWidget);
      expect(find.text('User ID'), findsNothing);
      expect(find.text('Profile ID'), findsNothing);
      expect(find.text('user-1'), findsNothing);
      expect(find.text('profile-1'), findsNothing);
      expect(find.text('80'), findsNothing);
      expect(find.text('never render this'), findsNothing);
    });

    testWidgets('uses role-specific Partner and Collector detail sets',
        (tester) async {
      await _pumpProfile(
        tester,
        UnifiedProfile.fromJson(_profile(AppRoles.partnerOrg)),
      );
      expect(find.text('Contact person'), findsOneWidget);
      expect(find.text('Contact number'), findsOneWidget);
      expect(find.text('Vehicle plate'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await _pumpProfile(
        tester,
        UnifiedProfile.fromJson(_profile(AppRoles.collector)),
      );
      expect(find.text('Vehicle type'), findsOneWidget);
      expect(find.text('Vehicle plate'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Collector Duty Status'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Collector Duty Status'), findsOneWidget);
      expect(find.text('Contact person'), findsNothing);
    });

    testWidgets('profile layout does not overflow a compact viewport',
        (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpProfile(
        tester,
        UnifiedProfile.fromJson(_profile(AppRoles.collector)),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('profile update contract', () {
    test('uses PUT /users/profile JSON and parses the 200 response', () async {
      final requests = <RequestOptions>[];
      final repository = UnifiedProfileRepository(
        api: UnifiedProfileApi(
          apiClient: ApiClient(dio: _recordingDio(requests)),
        ),
      );

      final updated = await repository.updateProfile(
        role: AppRoles.household,
        draft: const {
          'firstName': 'Maria',
          'lastName': 'Santos-Cruz',
          'phone': '+639171234567',
          'address': '123 Mabini St',
          'email': 'forbidden@example.com',
          'role': 'admin',
          'status': 'Active',
          'accountStatus': 'active',
          '_id': 'bad',
          'userId': 'bad',
          'profileId': 'bad',
        },
      );

      final request = requests.single;
      expect(request.method, 'PUT');
      expect(request.path, '/users/profile');
      expect(request.contentType, Headers.jsonContentType);
      expect(request.data, {
        'firstName': 'Maria',
        'lastName': 'Santos-Cruz',
        'phone': '+639171234567',
        'address': '123 Mabini St',
      });
      for (final forbidden in const {
        'email',
        'role',
        'status',
        'accountStatus',
        '_id',
        'userId',
        'profileId',
      }) {
        expect(request.data, isNot(contains(forbidden)));
      }
      expect(updated.userId, 'user-1');
      expect(updated.profileId, 'profile-1');
      expect(updated.role, AppRoles.household);
      expect(updated.accountStatus, 'active');
      expect(updated.userFields['firstName'], 'Maria');
    });

    test('builds household fields only', () {
      expect(
        UnifiedProfileRepository.buildProfilePayload(
          role: AppRoles.household,
          draft: const {
            'firstName': 'Maria',
            'lastName': 'Santos-Cruz',
            'phone': '+639171234567',
            'address': 'Quezon City',
            'organizationName': 'Excluded',
          },
        ),
        {
          'firstName': 'Maria',
          'lastName': 'Santos-Cruz',
          'phone': '+639171234567',
          'address': 'Quezon City',
        },
      );
    });

    test('builds partner organization fields only', () {
      expect(
        UnifiedProfileRepository.buildProfilePayload(
          role: AppRoles.partnerOrg,
          draft: const {
            'firstName': 'Juan',
            'lastName': 'Reyes',
            'organizationName': 'Barangay Central E-Waste Action',
            'contactPerson': 'Juan Reyes',
            'contactNumber': '+639189876543',
            'address': 'Barangay Hall',
            'phone': 'excluded',
          },
        ),
        {
          'firstName': 'Juan',
          'lastName': 'Reyes',
          'organizationName': 'Barangay Central E-Waste Action',
          'contactPerson': 'Juan Reyes',
          'contactNumber': '+639189876543',
          'address': 'Barangay Hall',
        },
      );
    });

    test('builds collector fields and accepts every vehicle type', () {
      for (final vehicleType in const {
        'Motorcycle',
        'Van',
        'Truck',
        'E-Trike',
        'Bike',
        'Other',
      }) {
        final payload = UnifiedProfileRepository.buildProfilePayload(
          role: AppRoles.collector,
          draft: {
            'firstName': 'Mario',
            'lastName': 'Driver',
            'phone': '+639201112233',
            'vehicleType': vehicleType,
            'vehiclePlate': 'ABC-1234',
            'address': 'excluded',
          },
        );
        expect(payload, {
          'firstName': 'Mario',
          'lastName': 'Driver',
          'phone': '+639201112233',
          'vehicleType': vehicleType,
          'vehiclePlate': 'ABC-1234',
        });
      }
    });

    test('validates names, phones, organization, vehicle type, and plate', () {
      expect(
        () => UnifiedProfileRepository.buildProfilePayload(
          role: AppRoles.household,
          draft: const {'firstName': 'M', 'lastName': 'Santos'},
        ),
        throwsA(isA<UnifiedProfileException>()),
      );
      expect(
        () => UnifiedProfileRepository.buildProfilePayload(
          role: AppRoles.partnerOrg,
          draft: const {
            'firstName': 'Juan',
            'lastName': 'Reyes',
            'organizationName': 'X',
            'contactNumber': 'bad phone',
          },
        ),
        throwsA(isA<UnifiedProfileException>()),
      );
      expect(
        () => UnifiedProfileRepository.buildProfilePayload(
          role: AppRoles.collector,
          draft: const {
            'firstName': 'Mario',
            'lastName': 'Driver',
            'vehicleType': 'Sedan',
            'vehiclePlate': 'ABC#1',
          },
        ),
        throwsA(isA<UnifiedProfileException>()),
      );
    });
  });

  group('password change contract', () {
    test('uses exact JSON body and preserves existing bearer session',
        () async {
      final requests = <RequestOptions>[];
      final repository = UnifiedProfileRepository(
        api: UnifiedProfileApi(
          apiClient: ApiClient(dio: _recordingDio(requests)),
        ),
      );

      final message = await repository.changePassword(
        currentPassword: 'OldPassword123!',
        newPassword: 'NewPassword456@',
      );

      final request = requests.single;
      expect(request.method, 'PUT');
      expect(request.path, '/users/change-password');
      expect(request.contentType, Headers.jsonContentType);
      expect(request.data, {
        'currentPassword': 'OldPassword123!',
        'newPassword': 'NewPassword456@',
      });
      expect(request.data, isNot(contains('confirmPassword')));
      expect(request.data, isNot(contains('email')));
      expect(request.data, isNot(contains('userId')));
      expect(request.headers['Authorization'], 'Bearer test');
      expect(message, 'Password updated successfully');
    });

    test('enforces every backend password-complexity component', () {
      expect(
        UnifiedProfileRepository.validatePassword('Old1!', 'Aa1@aaaa'),
        isNull,
      );
      for (final invalid in const {
        'Aa1@aaa',
        'aa1@aaaa',
        'AA1@AAAA',
        'Aaa@aaaa',
        'Aaa1aaaa',
        'Aaa1#aaaa',
      }) {
        expect(
          UnifiedProfileRepository.validatePassword('Old1!', invalid),
          isNotNull,
        );
      }
      expect(
        UnifiedProfileRepository.validatePassword('', 'Aa1@aaaa'),
        'Current password is required',
      );
      expect(
        UnifiedProfileRepository.validatePassword('Old1!', ''),
        'New password is required',
      );
    });

    test('surfaces safe wrong-current and weak-password backend messages',
        () async {
      for (final message in const {
        'Invalid current password',
        'New password is too weak',
      }) {
        final repository = UnifiedProfileRepository(
          api: _FailingProfileApi(message),
        );
        await expectLater(
          repository.changePassword(
            currentPassword: 'OldPassword123!',
            newPassword: 'NewPassword456@',
          ),
          throwsA(isA<UnifiedProfileException>().having(
            (error) => error.message,
            'message',
            message,
          )),
        );
      }
    });

    test('password form state is cleared without persistence', () {
      final fields = PasswordFieldControllers();
      fields.current.text = 'OldPassword123!';
      fields.next.text = 'NewPassword456@';
      fields.confirm.text = 'NewPassword456@';

      fields.clear();

      expect(fields.current.text, isEmpty);
      expect(fields.next.text, isEmpty);
      expect(fields.confirm.text, isEmpty);
      fields.dispose();
    });
  });

  test('Phase 8 still defines no profile-image or redemption route', () {
    final supported = [
      ApiEndpoints.rewardPoints,
      ApiEndpoints.userProfile,
      ApiEndpoints.changePassword,
    ];
    expect(supported.any((path) => path.contains('upload')), isFalse);
    expect(supported.any((path) => path.contains('redeem')), isFalse);
  });
}

Future<void> _pumpProfile(
  WidgetTester tester,
  UnifiedProfile profile,
) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) => MaterialApp(
        home: UnifiedProfileScreen(
          repository: _StaticProfileRepository(profile),
          collectorRepository: _StaticCollectorRepository(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Map<String, dynamic> _profile(String role) => {
      'message': 'Profile updated successfully',
      'accountStatus': 'active',
      'user': {
        '_id': 'user-1',
        'firstName': 'Maria',
        'lastName': 'Santos-Cruz',
        'email': 'actor@recytech.com',
        'role': role,
        'status': 'Active',
        'accountStatus': 'active',
      },
      'profile': {
        '_id': 'profile-1',
        'phone': '+639170000000',
        'address': 'Quezon City',
        'organizationName': 'RecyTech Org',
        'contactPerson': 'Maria Santos',
        'contactNumber': '+639170000000',
        'vehicleType': 'Truck',
        'vehiclePlate': 'ABC-1234',
      },
    };

Dio _recordingDio(List<RequestOptions> requests) {
  final dio = Dio(BaseOptions(headers: const {'Authorization': 'Bearer test'}));
  dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
    requests.add(options);
    final data = options.path == '/users/change-password'
        ? {'message': 'Password updated successfully'}
        : _profile('household');
    handler.resolve(Response(
      requestOptions: options,
      statusCode: 200,
      data: data,
    ));
  }));
  return dio;
}

class _FailingProfileApi extends UnifiedProfileApi {
  _FailingProfileApi(this.message);

  final String message;

  @override
  Future<Map<String, dynamic>> changePassword(
    Map<String, dynamic> fields,
  ) async {
    final options = RequestOptions(path: '/users/change-password');
    throw DioException(
      requestOptions: options,
      response: Response(
        requestOptions: options,
        statusCode: 400,
        data: {'message': message},
      ),
    );
  }
}

class _StaticProfileRepository extends UnifiedProfileRepository {
  _StaticProfileRepository(this.profile);

  final UnifiedProfile profile;

  @override
  Future<UnifiedProfile> fetchProfile() async => profile;
}

class _StaticCollectorRepository extends CollectorRepository {
  @override
  Future<CollectorProfile> fetchProfile() async => const CollectorProfile(
        profileId: 'collector-profile-1',
        userId: 'user-1',
        firstName: 'Maria',
        lastName: 'Santos-Cruz',
        email: 'collector@recytech.com',
        vehiclePlate: 'ABC-1234',
        vehicleType: 'Truck',
        status: 'Active',
        activeJobs: 0,
        completedJobs: 0,
      );
}
