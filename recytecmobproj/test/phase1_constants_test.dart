import 'package:flutter_test/flutter_test.dart';
import 'package:recytecmobproj/core/constants/app_constants.dart';
import 'package:recytecmobproj/core/utils/waste_type_mapper.dart';

void main() {
  group('role normalization', () {
    test('recognizes Household, LGU, and Collector variants', () {
      expect(AppRoles.normalize('Staff'), UserRole.household);
      expect(AppRoles.normalize('staff'), UserRole.household);
      expect(AppRoles.normalize('Household'), UserRole.household);
      expect(AppRoles.normalize('resident'), UserRole.household);
      expect(AppRoles.normalize('LGU'), UserRole.lgu);
      expect(AppRoles.normalize('lgu'), UserRole.lgu);
      expect(AppRoles.normalize('Collector'), UserRole.collector);
      expect(AppRoles.normalize('collector'), UserRole.collector);
    });

    test('routes supported roles to their production shells', () {
      expect(AppRoles.shellTargetFor('Staff'), AppShellTarget.household);
      expect(AppRoles.shellTargetFor('staff'), AppShellTarget.household);
      expect(AppRoles.shellTargetFor('LGU'), AppShellTarget.lgu);
      expect(AppRoles.shellTargetFor('lgu'), AppShellTarget.lgu);
      expect(AppRoles.shellTargetFor('Collector'), AppShellTarget.collector);
      expect(AppRoles.shellTargetFor('collector'), AppShellTarget.collector);
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
