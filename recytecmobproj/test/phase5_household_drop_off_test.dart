import 'package:flutter_test/flutter_test.dart';
import 'package:recytecmobproj/core/constants/app_constants.dart';
import 'package:recytecmobproj/core/utils/map_launcher.dart';
import 'package:recytecmobproj/data/models/bin_monitoring_models.dart';
import 'package:recytecmobproj/data/models/bin_qr_payload_model.dart';
import 'package:recytecmobproj/data/models/collected_item_model.dart';
import 'package:recytecmobproj/data/models/drop_off_record_model.dart';
import 'package:recytecmobproj/data/models/public_bin_model.dart';
import 'package:recytecmobproj/data/models/reward_transaction_model.dart';
import 'package:recytecmobproj/data/repositories/drop_off_repository.dart';

void main() {
  group('household QR payload parsing', () {
    test('parses valid RecyTech bin QR payloads', () {
      final payload = BinQrPayload.parse('recytech://bin/CONDO-3F-A');

      expect(payload.version, 1);
      expect(payload.publicBinCode, 'CONDO-3F-A');
      expect(payload.toQrValue(), 'recytech://bin/CONDO-3F-A');
      expect(payload.toJson(), isNot(contains('userId')));
      expect(payload.toJson(), isNot(contains('rewardPoints')));
    });

    test('rejects malformed QR values', () {
      expect(() => BinQrPayload.parse(''), throwsFormatException);
      expect(
          () => BinQrPayload.parse('not a recytech qr'), throwsFormatException);
    });

    test('rejects wrong RecyTech QR type', () {
      expect(
        () => BinQrPayload.parse('recytech://reward/CONDO-3F-A'),
        throwsFormatException,
      );
      expect(
        () => BinQrPayload.parse('recytech://bin/too/long'),
        throwsFormatException,
      );
    });
  });

  group('drop-off repository behavior', () {
    test('validates active bins without exposing raw internal data', () async {
      final repository = MockDropOffRepository();
      final bin = await repository.validateBinQr(
        BinQrPayload.parse('recytech://bin/CONDO-3F-A'),
      );

      expect(bin.name, 'RecyTech Bin A');
      expect(bin.publicQrCode, 'CONDO-3F-A');
      expect(bin.isActive, isTrue);
    });

    test('reports inactive or unknown bins', () async {
      final repository = MockDropOffRepository();

      expect(
        repository
            .validateBinQr(BinQrPayload.parse('recytech://bin/LIB-SOUTH')),
        throwsA(isA<DropOffRepositoryException>()),
      );
      expect(
        repository.validateBinQr(BinQrPayload.parse('recytech://bin/NOPE-000')),
        throwsA(isA<DropOffRepositoryException>()),
      );
    });

    test('replays duplicate idempotency keys without duplicate records',
        () async {
      final repository = MockDropOffRepository();
      final payload = BinQrPayload.parse('recytech://bin/MARKET-GATE2');

      final first = await repository.registerDropOff(
        payload: payload,
        submissionMethod: 'qr',
        idempotencyKey: 'idem-1',
        items: const [
          DropOffSubmissionItem(category: 'battery', quantity: 1),
        ],
      );
      final second = await repository.registerDropOff(
        payload: payload,
        submissionMethod: 'qr',
        idempotencyKey: 'idem-1',
        items: const [
          DropOffSubmissionItem(category: 'battery', quantity: 1),
        ],
      );

      expect(second.id, first.id);
    });
  });

  group('drop-off and reward models', () {
    test('parses backend public bin ownership and accepted categories', () {
      final bin = PublicBin.fromJson({
        '_id': '507f1f77bcf86cd799439011',
        'binCode': 'BIN-001',
        'publicQrCode': 'BIN-001',
        'name': 'Main Lobby E-Waste Bin',
        'partnerOrganizationName': 'Demo Partner Organization A',
        'address': 'Makati City Hall Main Lobby',
        'latitude': 14.5547,
        'longitude': 121.0244,
        'acceptedCategories': ['laptop', 'smartphone', 'pcb'],
        'acceptedCategoryDisplayNames': [
          {'value': 'laptop', 'label': 'Laptop'},
          {'value': 'smartphone', 'label': 'Smartphone'},
          {'value': 'pcb', 'label': 'PCB'},
        ],
      });

      expect(bin.publicQrCode, 'BIN-001');
      expect(bin.partnerOrganizationName, 'Demo Partner Organization A');
      expect(bin.acceptedCategories, ['laptop', 'smartphone', 'pcb']);
      expect(bin.acceptedCategoryLabels, ['Laptop', 'Smartphone', 'PCB']);
    });

    test('parses partner bin latest stored monitoring values', () {
      final bin = RecyTechBin.fromJson({
        'id': '507f1f77bcf86cd799439011',
        'binCode': 'BIN-002',
        'name': 'IT Office E-Waste Bin',
        'partnerOrganizationName': 'Demo Partner Organization A',
        'location': 'Makati City Hall IT Office',
        'fillPercentage': 78,
        'fullnessStatus': 'nearly_full',
        'sensorStatus': 'delayed',
        'lastUpdatedAt': '2026-08-28T09:15:00.000Z',
        'acceptedCategories': ['monitor', 'battery'],
      });

      expect(bin.binId, 'BIN-002');
      expect(bin.partnerOrganizationName, 'Demo Partner Organization A');
      expect(bin.fillPercentage, 78);
      expect(SensorStatuses.label(bin.sensorStatus), 'Delayed');
      expect(bin.acceptedCategoryLabels, ['Monitor', 'Battery']);
    });

    test('parses drop-off records with items and no weight requirement', () {
      final record = DropOffRecord.fromJson({
        'id': 'DROP-1',
        'binId': 'BIN-1',
        'binName': 'RecyTech Bin',
        'building': 'ABC Residences',
        'locationDescription': '3rd Floor',
        'createdAt': '2026-08-14T08:00:00Z',
        'status': 'submitted',
        'submissionMethod': 'manual',
        'pointsStatus': 'not_processed',
        'items': [
          {'category': 'laptop', 'categoryLabel': 'Laptop', 'quantity': 1},
        ],
      });

      expect(record.status, 'submitted');
      expect(record.submissionMethod, 'manual');
      expect(record.items.first.category, 'laptop');
      expect(record.items.first.quantity, 1);
      expect(record.pointsStatus, 'not_processed');
      expect(record.toJson(), isNot(contains('weightKg')));
    });

    test('parses backend-provided reward results', () {
      final reward = RewardTransaction.fromJson({
        'id': 'R-1',
        'dropOffId': 'DROP-1',
        'createdAt': '2026-08-14T08:00:00Z',
        'status': 'Credited',
        'points': 15,
        'binName': 'RecyTech Bin',
      });

      expect(reward.rewardLabel, '15 points');
      expect(reward.toJson(), containsPair('rewardPoints', 15));
      expect(reward.toJson(), isNot(contains('ratePerKg')));
    });
  });

  group('navigation and regression contracts', () {
    test('household shell target remains unchanged', () {
      expect(AppRoles.shellTargetFor('household'), AppShellTarget.household);
      expect(AppRoles.shellTargetFor('lgu'), AppShellTarget.partnerOrg);
      expect(AppRoles.shellTargetFor('collector'), AppShellTarget.collector);
    });

    test('map URLs are still shared for bin directions', () {
      const launcher = MapLauncher();
      final uri = launcher.googleMapsUri(
        const MapLaunchTarget(
          label: 'RecyTech Bin',
          address: 'ABC Residences',
        ),
      );

      expect(uri, isNotNull);
      expect(uri.toString(), contains('openstreetmap.org'));
    });

    test('LGU ToF model remains intact', () {
      final bin = RecyTechBin.fromJson({
        'id': 'BIN-LGU-1',
        'location': 'Municipal Hall',
        'distanceCm': 12.5,
        'fillPercentage': 80,
      });

      expect(bin.distanceCm, 12.5);
      expect(bin.fillPercentage, 80);
    });

    test('collector completion remains quantity-only with no weight field', () {
      final item = CollectedEWasteItem(
        id: 'I-1',
        imagePath: 'scan.jpg',
        aiPredictedClass: 'laptop',
        aiConfidence: 0.9,
        confirmedClass: 'laptop',
        quantity: 2,
      );

      expect(item.toJson(), containsPair('quantity', 2));
      expect(item.toJson(), isNot(contains('weightKg')));
      expect(item.toJson(), contains('aiPredictedClass'));
    });
  });
}
