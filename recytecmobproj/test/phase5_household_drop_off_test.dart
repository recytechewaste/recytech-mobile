import 'package:flutter_test/flutter_test.dart';
import 'package:recytecmobproj/core/constants/app_constants.dart';
import 'package:recytecmobproj/core/utils/map_launcher.dart';
import 'package:recytecmobproj/data/models/bin_monitoring_models.dart';
import 'package:recytecmobproj/data/models/bin_qr_payload_model.dart';
import 'package:recytecmobproj/data/models/collected_item_model.dart';
import 'package:recytecmobproj/data/models/drop_off_record_model.dart';
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
      expect(() => BinQrPayload.parse('not a recytech qr'), throwsFormatException);
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
        repository.validateBinQr(BinQrPayload.parse('recytech://bin/LIB-SOUTH')),
        throwsA(isA<DropOffRepositoryException>()),
      );
      expect(
        repository.validateBinQr(BinQrPayload.parse('recytech://bin/NOPE-000')),
        throwsA(isA<DropOffRepositoryException>()),
      );
    });

    test('surfaces duplicate reward responses from repository', () async {
      final repository = MockDropOffRepository();

      expect(
        repository.registerDropOff(
          payload: BinQrPayload.parse('recytech://bin/MARKET-GATE2'),
        ),
        throwsA(
          isA<DropOffRepositoryException>()
              .having((error) => error.code, 'code', 'duplicate_drop_off'),
        ),
      );
    });
  });

  group('drop-off and reward models', () {
    test('serializes drop-off records without category or quantity claims', () {
      final record = DropOffRecord.fromJson({
        'id': 'DROP-1',
        'binId': 'BIN-1',
        'binName': 'RecyTech Bin',
        'building': 'ABC Residences',
        'locationDescription': '3rd Floor',
        'createdAt': '2026-08-14T08:00:00Z',
        'status': 'Recorded',
        'rewardEligible': true,
        'rewardPoints': 10,
      });

      expect(record.rewardLabel, '10 points');
      expect(record.toJson(), isNot(contains('quantity')));
      expect(record.toJson(), isNot(contains('category')));
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
      expect(AppRoles.shellTargetFor('lgu'), AppShellTarget.lgu);
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
      expect(uri.toString(), contains('/maps/dir/'));
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
