import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recytecmobproj/core/network/api_client.dart';
import 'package:recytecmobproj/core/theme/recytechtheme.dart';
import 'package:recytecmobproj/data/models/bin_monitoring_models.dart';
import 'package:recytecmobproj/data/models/drop_off_record_model.dart';
import 'package:recytecmobproj/data/repositories/bin_monitoring_repository.dart';
import 'package:recytecmobproj/data/repositories/partner_organization_repository.dart';
import 'package:recytecmobproj/data/repositories/partner_validation_repository.dart';
import 'package:recytecmobproj/presentation/lgu/dashboard/lgu_dashboard_screen.dart';
import 'package:recytecmobproj/presentation/lgu/deposits/pending_dropoff_validations_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Partner validation repository', () {
    test('uses role-scoped list, filters status, and sends validation contract',
        () async {
      final requests = <RequestOptions>[];
      final repository = ApiPartnerValidationRepository(
        apiClient: ApiClient(dio: _partnerDio(requests)),
      );

      final pending = await repository.fetchPendingDropOffs();
      await repository.validateDropOff(
        'drop/1',
        action: 'approve',
        validationNotes: 'Photo and quantity verified.',
      );
      await repository.validateDropOff('drop/2', action: 'reject');

      expect(pending.map((record) => record.id), ['drop-1']);
      expect(requests[0].method, 'GET');
      expect(requests[0].path, '/bin-dropoffs');
      expect(requests[0].queryParameters, isEmpty);
      expect(requests[1].method, 'PATCH');
      expect(requests[1].path, '/bin-dropoffs/drop%2F1/validate');
      expect(requests[1].data, {
        'action': 'approve',
        'validationNotes': 'Photo and quantity verified.',
      });
      expect(requests[2].data, {'action': 'reject'});
      expect(
        requests.every(
          (request) =>
              request.data is! Map ||
              (!(request.data as Map).containsKey('userId') &&
                  !(request.data as Map).containsKey('profileId')),
        ),
        isTrue,
      );
    });

    test('parses submitted household details without exposing object dumps',
        () {
      final record = DropOffRecord.fromJson(_pendingJson());

      expect(record.createdAt, DateTime.parse('2026-09-10T02:15:00Z'));
      expect(record.householdName, 'Maria Santos');
      expect(record.householdEmail, 'maria@example.test');
      expect(record.notes, 'Old laptop with charger.');
      expect(record.imageUrls.single, startsWith('data:image/png;base64,'));
    });
  });

  group('Partner dashboard', () {
    testWidgets('renders exactly the four approved metrics and no raw fields',
        (tester) async {
      final requests = <RequestOptions>[];
      final client = ApiClient(dio: _partnerDio(requests));
      await tester.pumpWidget(_testApp(
        LguDashboardScreen(
          binRepository: ApiPartnerBinRepository(apiClient: client),
          partnerRepository: PartnerOrganizationRepository(apiClient: client),
          validationRepository:
              ApiPartnerValidationRepository(apiClient: client),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Assigned Bins Count'), findsOneWidget);
      expect(find.text('Pending Validations'), findsOneWidget);
      expect(find.text('Total Dropoffs Validated'), findsOneWidget);
      expect(find.text('Completed Collections'), findsOneWidget);
      expect(find.byKey(const Key('metric-assigned-bins')), findsOneWidget);
      expect(
          find.byKey(const Key('metric-pending-validations')), findsOneWidget);
      expect(
          find.byKey(const Key('metric-validated-dropoffs')), findsOneWidget);
      expect(find.byKey(const Key('metric-completed-collections')),
          findsOneWidget);

      for (final forbidden in [
        'Partner Org ID',
        'partner-profile-1',
        'Total Points Distributed',
        'Total Items Received',
        'Category Breakdown',
        'Priority bins',
        'Unknown Backend Metric',
      ]) {
        expect(find.textContaining(forbidden), findsNothing);
      }
    });

    testWidgets('only Pending Validations is interactive', (tester) async {
      final requests = <RequestOptions>[];
      final client = ApiClient(dio: _partnerDio(requests));
      await tester.pumpWidget(_testApp(
        LguDashboardScreen(
          binRepository: ApiPartnerBinRepository(apiClient: client),
          partnerRepository: PartnerOrganizationRepository(apiClient: client),
          validationRepository:
              ApiPartnerValidationRepository(apiClient: client),
        ),
      ));
      await tester.pumpAndSettle();

      expect(
          find.byKey(const Key('pending-validations-action')), findsOneWidget);
      for (final key in [
        'metric-assigned-bins',
        'metric-validated-dropoffs',
        'metric-completed-collections',
      ]) {
        expect(
          find.ancestor(
            of: find.byKey(Key(key)),
            matching: find.byType(InkWell),
          ),
          findsNothing,
        );
      }

      final pendingAction = find.byKey(
        const Key('pending-validations-action'),
      );
      await tester.ensureVisible(pendingAction);
      await tester.pumpAndSettle();
      await tester.tap(pendingAction);
      await tester.pumpAndSettle();
      expect(find.text('Pending Validations'), findsOneWidget);
      expect(find.byKey(const Key('pending-validations-list')), findsOneWidget);
    });

    testWidgets('refreshes dashboard after a validation changed the list',
        (tester) async {
      final repository = _FakeValidationRepository([_pendingRecord()]);
      final bins = _FakeBinRepository();
      final partner = PartnerOrganizationRepository(
        apiClient: ApiClient(dio: _partnerDio(<RequestOptions>[])),
      );
      await tester.pumpWidget(_testApp(
        LguDashboardScreen(
          binRepository: bins,
          partnerRepository: partner,
          validationRepository: repository,
        ),
      ));
      await tester.pumpAndSettle();
      expect(repository.fetchCalls, 1);

      final pendingAction = find.byKey(
        const Key('pending-validations-action'),
      );
      await tester.ensureVisible(pendingAction);
      await tester.pumpAndSettle();
      await tester.tap(pendingAction);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pending-dropoff-drop-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('validate-dropoff-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('approve-dropoff-button')));
      await tester.pumpAndSettle();
      expect(find.text('No pending validations'), findsOneWidget);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Dashboard'), findsOneWidget);
      expect(repository.fetchCalls, greaterThanOrEqualTo(4));
    });
  });

  group('Pending validation UI', () {
    testWidgets('shows loading, then a polished empty state', (tester) async {
      final completer = Completer<List<DropOffRecord>>();
      final repository = _FakeValidationRepository(
        const [],
        fetchCompleter: completer,
      );
      await tester.pumpWidget(
        _testApp(PendingDropOffValidationsScreen(repository: repository)),
      );
      await tester.pump();
      expect(find.text('Loading pending validations…'), findsOneWidget);

      completer.complete([]);
      await tester.pumpAndSettle();
      expect(find.text('No pending validations'), findsOneWidget);
      expect(
        find.text(
          'New household drop-offs assigned to your bins will appear here.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows sanitized error and manual retry', (tester) async {
      final repository = _FakeValidationRepository(
        const [],
        failFetchCount: 1,
      );
      await tester.pumpWidget(
        _testApp(PendingDropOffValidationsScreen(repository: repository)),
      );
      await tester.pumpAndSettle();

      expect(
          find.text('We could not load pending validations.'), findsOneWidget);
      expect(find.textContaining('DioException'), findsNothing);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('No pending validations'), findsOneWidget);
      expect(repository.fetchCalls, 2);
    });

    testWidgets('renders only pending cards and opens safe full details',
        (tester) async {
      final repository = _FakeValidationRepository([
        _pendingRecord(),
        _record(id: 'drop-approved', status: DropOffStatuses.approved),
        _record(id: 'drop-rejected', status: DropOffStatuses.rejected),
      ]);
      await tester.pumpWidget(
        _testApp(PendingDropOffValidationsScreen(repository: repository)),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pending-dropoff-drop-1')), findsOneWidget);
      expect(
          find.byKey(const Key('pending-dropoff-drop-approved')), findsNothing);
      expect(
          find.byKey(const Key('pending-dropoff-drop-rejected')), findsNothing);
      expect(find.text('Laptop'), findsOneWidget);
      expect(find.text('Main Lobby Bin'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const Key('pending-dropoff-drop-1')));
      await tester.pumpAndSettle();
      expect(find.text('Review Drop-Off'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Maria Santos'),
        250,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Maria Santos'), findsOneWidget);
      expect(find.text('maria@example.test'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Old laptop with charger.'),
        250,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Old laptop with charger.'), findsOneWidget);
      expect(find.textContaining('data:image'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('approves once, prevents duplicate taps, and removes item',
        (tester) async {
      final validationCompleter = Completer<void>();
      final repository = _FakeValidationRepository(
        [_pendingRecord()],
        validationCompleter: validationCompleter,
      );
      await tester.pumpWidget(
        _testApp(PendingDropOffValidationsScreen(repository: repository)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pending-dropoff-drop-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('validate-dropoff-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('approve-dropoff-button')));
      await tester.pump();

      final validatingButton = tester.widget<FilledButton>(
        find.byKey(const Key('validate-dropoff-button')),
      );
      expect(validatingButton.onPressed, isNull);
      await tester.tap(
        find.byKey(const Key('validate-dropoff-button')),
        warnIfMissed: false,
      );
      expect(repository.validateCalls, 1);

      validationCompleter.complete();
      await tester.pumpAndSettle();
      expect(repository.actions, ['approve']);
      expect(find.text('No pending validations'), findsOneWidget);
      expect(find.text('Drop-off approved successfully.'), findsOneWidget);
    });

    testWidgets('rejects with optional validation notes', (tester) async {
      final repository = _FakeValidationRepository([_pendingRecord()]);
      await tester.pumpWidget(
        _testApp(PendingDropOffValidationsScreen(repository: repository)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pending-dropoff-drop-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('validate-dropoff-button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        'Image does not match the submitted category.',
      );
      await tester.tap(find.byKey(const Key('reject-dropoff-button')));
      await tester.pumpAndSettle();

      expect(repository.actions, ['reject']);
      expect(repository.notes.single,
          'Image does not match the submitted category.');
      expect(find.text('No pending validations'), findsOneWidget);
      expect(find.text('Drop-off rejected successfully.'), findsOneWidget);
    });

    testWidgets('does not overflow at a compact representative phone size',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _testApp(
          PendingDropOffValidationsScreen(
            repository: _FakeValidationRepository([_pendingRecord()]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}

Widget _testApp(Widget child) => ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      builder: (_, __) => MaterialApp(
        theme: RecyTechTheme.light(),
        home: child,
      ),
    );

Dio _partnerDio(List<RequestOptions> requests) {
  final dio = Dio(
    BaseOptions(headers: const {'Authorization': 'Bearer test-token'}),
  );
  dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
    requests.add(options);
    dynamic data;
    if (options.path == '/partner-organizations/me') {
      data = {
        'profile': {
          '_id': 'partner-profile-1',
          'organizationName': 'Green Municipality',
        },
        'user': {'_id': 'user-1', 'email': 'partner@example.test'},
        'overview': {
          'assignedBins': 999,
          'partnerOrgId': 'raw-profile-id',
          'totalItemsReceived': 800,
          'categoryBreakdown': {'laptop': 4},
        },
      };
    } else if (options.path == '/partner-organizations/stats') {
      data = {
        'validatedDropOffs': 12,
        'completedCollections': 8,
        'pointsAwarded': 420,
        'unknownBackendMetric': 999,
      };
    } else if (options.path == '/partner-organizations/my-bins') {
      data = {
        'bins': [
          {
            '_id': 'bin-1',
            'name': 'Main Lobby Bin',
            'address': 'Town Hall',
            'status': 'Operational',
          },
        ],
      };
    } else if (options.path == '/bin-dropoffs' && options.method == 'GET') {
      data = {
        'dropoffs': [
          _pendingJson(),
          {
            ..._pendingJson(),
            '_id': 'drop-approved',
            'status': 'approved',
          },
        ],
      };
    } else {
      data = {'success': true};
    }
    handler.resolve(Response(requestOptions: options, data: data));
  }));
  return dio;
}

Map<String, dynamic> _pendingJson() => {
      '_id': 'drop-1',
      'status': 'pending',
      'submittedAt': '2026-09-10T02:15:00Z',
      'wasteType': 'laptop',
      'quantity': 1,
      'bin': {
        '_id': 'bin-1',
        'name': 'Main Lobby Bin',
        'address': 'Town Hall, Ground Floor',
      },
      'resident': {
        '_id': 'resident-profile-1',
        'name': 'Maria Santos',
        'email': 'maria@example.test',
      },
      'notes': 'Old laptop with charger.',
      'image':
          'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJ'
              'AAAADUlEQVQIHWP4z8DwHwAFgAI/ScLz9QAAAABJRU5ErkJggg==',
      'pointsProjected': 25,
    };

DropOffRecord _pendingRecord() => DropOffRecord.fromJson(_pendingJson());

DropOffRecord _record({required String id, required String status}) =>
    DropOffRecord.fromJson({..._pendingJson(), '_id': id, 'status': status});

class _FakeValidationRepository implements PartnerValidationRepository {
  _FakeValidationRepository(
    List<DropOffRecord> records, {
    this.fetchCompleter,
    this.validationCompleter,
    this.failFetchCount = 0,
  }) : _records = List.of(records);

  final List<DropOffRecord> _records;
  final Completer<List<DropOffRecord>>? fetchCompleter;
  final Completer<void>? validationCompleter;
  int failFetchCount;
  int fetchCalls = 0;
  int validateCalls = 0;
  final List<String> actions = [];
  final List<String?> notes = [];

  @override
  Future<List<DropOffRecord>> fetchPendingDropOffs() async {
    fetchCalls++;
    if (failFetchCount > 0) {
      failFetchCount--;
      throw const PartnerValidationException(
        'DioException with raw backend details',
      );
    }
    if (fetchCompleter != null && !fetchCompleter!.isCompleted) {
      return fetchCompleter!.future;
    }
    return List.of(_records);
  }

  @override
  Future<void> validateDropOff(
    String id, {
    required String action,
    String? validationNotes,
  }) async {
    validateCalls++;
    actions.add(action);
    notes.add(validationNotes);
    if (validationCompleter != null) await validationCompleter!.future;
    _records.removeWhere((record) => record.id == id);
  }
}

class _FakeBinRepository implements LguBinRepository {
  final _bin = RecyTechBin.fromJson({
    '_id': 'bin-1',
    'name': 'Main Lobby Bin',
    'address': 'Town Hall',
    'status': 'Operational',
  });

  @override
  Future<List<RecyTechBin>> fetchAssignedBins() async => [_bin];

  @override
  Future<RecyTechBin> fetchBin(String binId) async => _bin;

  @override
  Future<BinMonitoringData> fetchMonitoring(String binId) async =>
      throw UnimplementedError();

  @override
  Future<RecyTechBin> updateBinStatus({
    required String binId,
    required String status,
    double? fillLevelKg,
    String? notes,
  }) async =>
      _bin;
}
