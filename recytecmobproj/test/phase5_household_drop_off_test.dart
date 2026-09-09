import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recytecmobproj/core/constants/app_constants.dart';
import 'package:recytecmobproj/core/network/api_client.dart';
import 'package:recytecmobproj/core/network/api_endpoints.dart';
import 'package:recytecmobproj/core/utils/map_launcher.dart';
import 'package:recytecmobproj/data/models/bin_monitoring_models.dart';
import 'package:recytecmobproj/data/models/bin_qr_payload_model.dart';
import 'package:recytecmobproj/data/models/collected_item_model.dart';
import 'package:recytecmobproj/data/models/drop_off_record_model.dart';
import 'package:recytecmobproj/data/models/public_bin_model.dart';
import 'package:recytecmobproj/data/models/reward_transaction_model.dart';
import 'package:recytecmobproj/data/repositories/drop_off_repository.dart';
import 'package:recytecmobproj/data/repositories/public_bin_repository.dart';

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

    test('extracts canonical qrCode from raw, JSON, and URL values', () {
      expect(BinQrPayload.parse('BIN-QC-001').publicBinCode, 'BIN-QC-001');
      expect(
        BinQrPayload.parse('{"qrCode":"BIN-QC-002"}').publicBinCode,
        'BIN-QC-002',
      );
      expect(
        BinQrPayload.parse(
          'https://recytech.example/bin-locations/public/qr/BIN-QC-003',
        ).publicBinCode,
        'BIN-QC-003',
      );
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

    test('mock submission remains pending without local points credit',
        () async {
      final repository = MockDropOffRepository();
      final payload = BinQrPayload.parse('recytech://bin/MARKET-GATE2');

      final result = await repository.registerDropOff(
        payload: payload,
        wasteType: 'battery',
        quantity: 1,
      );

      expect(result.dropOff.status, DropOffStatuses.pending);
      expect(result.dropOff.pointsAwarded, 0);
      expect(result.projectedPoints, isNull);
      expect(result.dropOff.transactionId, isNull);
    });
  });

  group('Phase 5 canonical endpoints', () {
    test('constructs encoded bin QR and drop-off detail paths', () {
      expect(ApiEndpoints.binLocations, '/bin-locations');
      expect(
        ApiEndpoints.publicBinByQrCode('BIN QC/1'),
        '/bin-locations/public/qr/BIN%20QC%2F1',
      );
      expect(ApiEndpoints.binDropoffs, '/bin-dropoffs');
      expect(ApiEndpoints.binDropoffById('drop/1'), '/bin-dropoffs/drop%2F1');
    });

    test('bin list, QR lookup, history, and detail use canonical paths',
        () async {
      final requests = <RequestOptions>[];
      final dio = _recordingDio(requests);
      final client = ApiClient(dio: dio);

      await ApiPublicBinRepository(apiClient: client).fetchPublicBins();
      final repository = ApiDropOffRepository(apiClient: client);
      await repository.validateBinQr(BinQrPayload.parse('BIN-QC-001'));
      await repository.getMyDropOffHistory();
      await repository.getDropOffDetail('DROP-1');

      expect(
        requests.map((request) => request.path),
        [
          '/bin-locations',
          '/bin-locations/public/qr/BIN-QC-001',
          '/bin-dropoffs',
          '/bin-dropoffs/DROP-1',
        ],
      );
      expect(requests.every((request) => request.method == 'GET'), isTrue);
      expect(
        requests
            .every((request) => !request.queryParameters.containsKey('userId')),
        isTrue,
      );
    });

    test('POSTs the authenticated binId JSON contract and parses 201',
        () async {
      final requests = <RequestOptions>[];
      final repository = ApiDropOffRepository(
        apiClient: ApiClient(dio: _recordingDio(requests)),
      );

      final result = await repository.registerDropOff(
        bin: PublicBin.fromJson({
          '_id': '67ca392fa998a72b0c111222',
          'name': 'Bin',
          'address': 'Address',
          'qrCode': 'BIN-QC-001',
          'status': 'Operational',
        }),
        wasteType: 'small_electronics',
        quantity: 2,
        notes: 'Old router',
        image: 'data:image/jpeg;base64,YWJj',
      );

      final request = requests.single;
      expect(request.method, 'POST');
      expect(request.path, '/bin-dropoffs');
      expect(request.contentType, Headers.jsonContentType);
      expect(request.data, {
        'binId': '67ca392fa998a72b0c111222',
        'wasteType': 'Small Electronics',
        'quantity': 2,
        'notes': 'Old router',
        'image': 'data:image/jpeg;base64,YWJj',
      });
      expect(request.data, isNot(contains('qrCode')));
      expect(request.data, isNot(contains('residentId')));
      expect(request.data, isNot(contains('userId')));
      expect(request.data, isNot(contains('profileId')));
      expect(request.data, isNot(contains('items')));
      expect(result.message, 'Drop-off logged successfully');
      expect(result.dropOff.id, 'DROP-201');
      expect(result.dropOff.status, DropOffStatuses.pending);
      expect(result.dropOff.items.single.category, 'Small Electronics');
      expect(result.dropOff.items.single.quantity, 2);
      expect(result.dropOff.pointsAwarded, 0);
      expect(result.dropOff.pointsProjected, 50);
      expect(result.dropOff.rejectionNotes, isNull);
      expect(result.projectedPoints, 50);
      expect(result.dropOff.transactionId, isNull);
    });

    test(
        'POSTs qrCode with decimal or zero quantity and optional fields omitted',
        () async {
      final requests = <RequestOptions>[];
      final repository = ApiDropOffRepository(
        apiClient: ApiClient(dio: _recordingDio(requests)),
      );

      await repository.registerDropOff(
        payload: BinQrPayload.parse('BIN-QC-001'),
        wasteType: 'Battery',
        quantity: 1.5,
      );
      await repository.registerDropOff(
        payload: BinQrPayload.parse('BIN-QC-002'),
        wasteType: 'Battery',
        quantity: 0,
      );

      expect(requests[0].data, {
        'qrCode': 'BIN-QC-001',
        'wasteType': 'Battery',
        'quantity': 1.5,
      });
      expect(requests[1].data, {
        'qrCode': 'BIN-QC-002',
        'wasteType': 'Battery',
        'quantity': 0,
      });
      expect(requests.every((request) => !request.data.containsKey('image')),
          isTrue);
      expect(requests.every((request) => !request.data.containsKey('notes')),
          isTrue);
    });

    test('maps only the eight canonical backend waste types', () {
      const expected = {
        'battery': 'Battery',
        'small_electronics': 'Small Electronics',
        'cables & wires': 'Cables & Wires',
        'smartphone': 'Mobile Devices',
        'pcb': 'Motherboards',
        'laptop': 'Laptops',
        'peripheral': 'Peripherals',
        'monitor': 'Monitors',
      };
      for (final entry in expected.entries) {
        expect(DropOffWasteTypes.canonicalize(entry.key), entry.value);
      }
      expect(DropOffWasteTypes.values, expected.values.toSet());
      expect(DropOffWasteTypes.canonicalize('legacy appliance'), isNull);
    });
  });

  group('drop-off and reward models', () {
    test('parses backend public bin ownership and accepted categories', () {
      final bin = PublicBin.fromJson({
        '_id': '507f1f77bcf86cd799439011',
        'binCode': 'BIN-001',
        'publicQrCode': 'BIN-001',
        'name': 'Main Lobby E-Waste Bin',
        'status': 'Operational',
        'location': {
          'type': 'Point',
          'coordinates': [121.0244, 14.5547],
        },
        'assignedLgu': {
          '_id': 'LGU-1',
          'name': 'Demo Partner Organization A',
          'contactPerson': 'Hon. Santos',
          'email': 'central@lgu.gov.ph',
          'phone': '09171234567',
        },
        'address': 'Makati City Hall Main Lobby',
        'acceptedCategories': ['laptop', 'smartphone', 'pcb'],
        'acceptedCategoryDisplayNames': [
          {'value': 'laptop', 'label': 'Laptop'},
          {'value': 'smartphone', 'label': 'Smartphone'},
          {'value': 'pcb', 'label': 'PCB'},
        ],
      });

      expect(bin.publicQrCode, 'BIN-001');
      expect(bin.partnerOrganizationName, 'Demo Partner Organization A');
      expect(bin.assignedLguId, 'LGU-1');
      expect(bin.assignedLguContactPerson, 'Hon. Santos');
      expect(bin.latitude, 14.5547);
      expect(bin.longitude, 121.0244);
      expect(bin.isActive, isTrue);
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
        'status': 'pending',
        'submissionMethod': 'manual',
        'pointsStatus': 'not_processed',
        'items': [
          {'category': 'laptop', 'categoryLabel': 'Laptop', 'quantity': 1},
        ],
      });

      expect(record.status, DropOffStatuses.pending);
      expect(record.statusLabel, 'Pending');
      expect(record.submissionMethod, 'manual');
      expect(record.items.first.category, 'laptop');
      expect(record.items.first.quantity, 1);
      expect(record.pointsStatus, 'not_processed');
      expect(record.toJson(), isNot(contains('weightKg')));
    });

    test('keeps API status separate from display labels', () {
      expect(DropOffStatuses.normalize('submitted'), DropOffStatuses.pending);
      expect(DropOffStatuses.label('pending'), 'Pending');
      expect(DropOffStatuses.label('approved'), 'Approved');
      expect(DropOffStatuses.label('rejected'), 'Rejected');
    });

    test('parses rejection notes and linked transaction without local awards',
        () {
      final rejected = DropOffRecord.fromJson({
        '_id': 'DROP-REJECTED',
        'bin': {'_id': 'BIN-1', 'name': 'Main Bin'},
        'createdAt': '2026-08-14T08:00:00Z',
        'status': 'rejected',
        'category': 'laptop',
        'quantity': 1,
        'rejectionNotes': 'Unsupported item condition.',
        'pointsAwarded': 0,
      });
      final approved = DropOffRecord.fromJson({
        '_id': 'DROP-APPROVED',
        'bin': {'_id': 'BIN-1', 'name': 'Main Bin'},
        'createdAt': '2026-08-14T08:00:00Z',
        'status': 'approved',
        'category': 'laptop',
        'quantity': 1,
        'pointsAwarded': 15,
        'transaction': {'_id': 'TX-1'},
      });

      expect(rejected.rejectionNotes, 'Unsupported item condition.');
      expect(rejected.pointsAwarded, 0);
      expect(approved.pointsAwarded, 15);
      expect(approved.transactionId, 'TX-1');
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

Dio _recordingDio(List<RequestOptions> requests) {
  final dio = Dio(
    BaseOptions(headers: const {'Authorization': 'Bearer test-token'}),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        requests.add(options);
        dynamic data;
        if (options.path == '/bin-locations') {
          data = {
            'bins': [
              {
                '_id': 'BIN-1',
                'name': 'Main Bin',
                'address': '123 Main St',
                'qrCode': 'BIN-QC-001',
                'status': 'Operational',
              },
            ],
          };
        } else if (options.path.startsWith('/bin-locations/public/qr/')) {
          data = {
            '_id': 'BIN-1',
            'name': 'Main Bin',
            'address': '123 Main St',
            'qrCode': 'BIN-QC-001',
            'status': 'Operational',
          };
        } else if (options.path == '/bin-dropoffs' &&
            options.method == 'POST') {
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 201,
              data: {
                'message': 'Drop-off logged successfully',
                'dropoff': {
                  '_id': 'DROP-201',
                  'bin': options.data['binId'] ?? options.data['qrCode'],
                  'wasteType': options.data['wasteType'],
                  'quantity': options.data['quantity'],
                  'status': 'pending',
                  'pointsAwarded': 0,
                  'pointsProjected': 50,
                  'rejectionReason': null,
                  'createdAt': '2026-09-08T08:00:00Z',
                },
                'projectedPoints': 50,
              },
            ),
          );
          return;
        } else if (options.path == '/bin-dropoffs') {
          data = {'dropOffs': <Object>[]};
        } else {
          data = {
            '_id': 'DROP-1',
            'bin': {'_id': 'BIN-1', 'name': 'Main Bin'},
            'createdAt': '2026-08-14T08:00:00Z',
            'status': 'pending',
            'category': 'laptop',
            'quantity': 1,
          };
        }
        handler.resolve(Response(requestOptions: options, data: data));
      },
    ),
  );
  return dio;
}
