import 'package:flutter_test/flutter_test.dart';
import 'package:recytecmobproj/core/constants/app_constants.dart';
import 'package:recytecmobproj/core/utils/waste_type_mapper.dart';
import 'package:recytecmobproj/data/models/user_model.dart';

void main() {
  group('role normalization', () {
    test('recognizes Household, Partner Organization, and Collector variants',
        () {
      expect(AppRoles.normalize('Staff'), UserRole.unsupported);
      expect(AppRoles.normalize('staff'), UserRole.unsupported);
      expect(AppRoles.normalize('Household'), UserRole.household);
      expect(AppRoles.normalize('resident'), UserRole.household);
      expect(AppRoles.normalize('LGU'), UserRole.partnerOrg);
      expect(AppRoles.normalize('lgu'), UserRole.partnerOrg);
      expect(AppRoles.normalize('partner_org'), UserRole.partnerOrg);
      expect(AppRoles.normalize('Partner Organization'), UserRole.partnerOrg);
      expect(AppRoles.normalize('PartnerOrganization'), UserRole.partnerOrg);
      expect(AppRoles.normalize('Collector'), UserRole.collector);
      expect(AppRoles.normalize('collector'), UserRole.collector);
    });

    test('returns canonical API roles for auth payloads', () {
      expect(AppRoles.canonicalApiRole('registered_user'), AppRoles.household);
      expect(AppRoles.canonicalApiRole('Staff'), isNull);
      expect(
        AppRoles.canonicalApiRole('Partner Organization'),
        AppRoles.partnerOrg,
      );
      expect(AppRoles.canonicalApiRole('LGU'), AppRoles.partnerOrg);
      expect(AppRoles.canonicalApiRole('Collector'), AppRoles.collector);
      expect(AppRoles.canonicalApiRole('admin'), isNull);
    });

    test('routes supported roles to their production shells', () {
      expect(AppRoles.shellTargetFor('Staff'), AppShellTarget.accessDenied);
      expect(AppRoles.shellTargetFor('staff'), AppShellTarget.accessDenied);
      expect(AppRoles.shellTargetFor('LGU'), AppShellTarget.partnerOrg);
      expect(AppRoles.shellTargetFor('lgu'), AppShellTarget.partnerOrg);
      expect(AppRoles.shellTargetFor('partner_org'), AppShellTarget.partnerOrg);
      expect(
        AppRoles.shellTargetFor('Partner Organization'),
        AppShellTarget.partnerOrg,
      );
      expect(AppRoles.shellTargetFor('Collector'), AppShellTarget.collector);
      expect(AppRoles.shellTargetFor('collector'), AppShellTarget.collector);
    });

    test('preserves backend partner_org on authenticated users', () {
      final user = UserModel.fromJson({
        '_id': 'partner-1',
        'fullName': 'Demo Partner',
        'email': 'partner@example.com',
        'role': 'partner_org',
        'accountStatus': 'active',
        'profileId': 'partner-profile-1',
      });

      expect(user.role, AppRoles.partnerOrg);
      expect(AppRoles.normalize(user.role), UserRole.partnerOrg);
      expect(AppRoles.shellTargetFor(user.role), AppShellTarget.partnerOrg);
      expect(AppRoles.canonicalApiRole(user.role), AppRoles.partnerOrg);
    });

    test('does not route unknown roles into target shells', () {
      expect(AppRoles.normalize('admin'), UserRole.unsupported);
      expect(AppRoles.shellTargetFor('admin'), AppShellTarget.accessDenied);
      expect(AppRoles.canUseLguShell(UserRole.unsupported), isFalse);
      expect(AppRoles.canUseHouseholdShell(UserRole.unsupported), isFalse);
    });
  });

  group('status constants', () {
    test('formats fullness statuses', () {
      expect(FullnessStatuses.label('nearly-full'), 'Nearly Full');
      expect(FullnessStatuses.label('sensor offline'), 'Sensor Offline');
    });

    test('identifies active request statuses', () {
      expect(
        CollectionRequestStatuses.isActive('collector_assigned'),
        isTrue,
      );
      expect(CollectionRequestStatuses.isActive('completed'), isFalse);
    });
  });

  group('YOLO label mapping', () {
    test('preserves model labels and maps to backend names', () {
      expect(WasteTypeMapper.toBackendWasteType('PCB'), 'PCB');
      expect(
        WasteTypeMapper.toBackendWasteType('washing_machine'),
        'Washing Machine',
      );
      expect(
        WasteTypeMapper.toBackendWasteType('air_conditioner'),
        'Air Conditioner',
      );
    });
  });
}
