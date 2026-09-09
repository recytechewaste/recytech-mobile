import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recytecmobproj/core/network/api_client.dart';
import 'package:recytecmobproj/core/network/api_endpoints.dart';
import 'package:recytecmobproj/data/datasources/collector_api.dart';
import 'package:recytecmobproj/data/models/bin_monitoring_models.dart';
import 'package:recytecmobproj/data/models/drop_off_record_model.dart';
import 'package:recytecmobproj/data/models/sensor_incident_model.dart';
import 'package:recytecmobproj/data/models/unified_profile_model.dart';
import 'package:recytecmobproj/data/repositories/collection_request_repository.dart';
import 'package:recytecmobproj/data/repositories/collector_repository.dart';
import 'package:recytecmobproj/data/repositories/drop_off_repository.dart';
import 'package:recytecmobproj/data/repositories/sensor_incident_repository.dart';
import 'package:recytecmobproj/presentation/lgu/sensor_incidents/sensor_incident_form_screen.dart';
import 'package:recytecmobproj/presentation/lgu/requests/collection_request_form_screen.dart';

void main() {
  group('Phase 9 sensor incident API contract', () {
    test('uses canonical create and Partner history endpoints', () {
      expect(ApiEndpoints.sensorReports, '/sensor-reports');
      expect(ApiEndpoints.sensorReportsMyReports, '/sensor-reports/my-reports');
    });

    test('preserves Mongo _id separately from the public bin code', () {
      final bin = RecyTechBin.fromJson({
        '_id': 'mongo-bin-1',
        'binId': 'BIN-001',
        'name': 'Plaza Bin',
        'address': 'Town Plaza',
      });

      expect(bin.binId, 'BIN-001');
      expect(bin.apiId, 'mongo-bin-1');
      expect(bin.requestBinId, 'mongo-bin-1');
    });

    test('does not substitute generic id or recycling center id for requests',
        () {
      final bin = RecyTechBin.fromJson({
        'id': 'recycling-center-1',
        'binId': 'BIN-001',
        'qrCode': 'QR-001',
        'recyclingCenterId': {
          '_id': 'recycling-center-2',
        },
        'name': 'NU Trash Org',
        'address': 'Pinned at 14.6047, 120.9942',
      });

      expect(bin.databaseId, isNull);
      expect(bin.binId, 'BIN-001');
      expect(bin.publicQrCode, 'QR-001');
      expect(bin.recyclingCenterId, 'recycling-center-2');
      expect(bin.requestBinId, 'BIN-001');
      expect(bin.requestBinId, isNot('recycling-center-1'));
      expect(bin.requestBinId, isNot('recycling-center-2'));
    });

    test('does not fabricate a request identifier from generic id alone', () {
      final bin = RecyTechBin.fromJson({
        'id': 'recycling-center-1',
        'recyclingCenterId': 'recycling-center-2',
        'name': 'NU Trash Org',
        'address': 'Pinned at 14.6047, 120.9942',
      });

      expect(bin.databaseId, isNull);
      expect(bin.binId, isEmpty);
      expect(bin.requestBinId, isEmpty);
    });

    test('creates exact identity-free body with default ToF sensor', () async {
      final requests = <RequestOptions>[];
      final repository = ApiSensorIncidentRepository(
        apiClient: ApiClient(dio: _sensorDio(requests)),
      );

      final result = await repository.createIncident(
        binId: 'mongo-bin-1',
        issueDescription: 'naapaw na',
      );

      final request = requests.single;
      expect(request.method, 'POST');
      expect(request.path, '/sensor-reports');
      expect(request.contentType, Headers.jsonContentType);
      expect(request.data, {
        'binId': 'mongo-bin-1',
        'issueDescription': 'naapaw na',
        'severity': 'Medium',
        'sensorType': 'Time-of-Flight (ToF) Fullness Sensor',
      });
      for (final forbidden in const {
        'partnerOrgId',
        'profileId',
        'userId',
        'reportedBy',
        'reporterName',
        'reporterEmail',
        'status',
        'createdAt',
        'notes',
        'description',
        'address',
        'location',
        'locationDescription',
        'publicDescription',
        'dropOffDescription',
      }) {
        expect(request.data, isNot(contains(forbidden)));
      }
      expect(result.success, isTrue);
      expect(result.incident.id, 'incident-1');
      expect(result.incident.bin.id, 'mongo-bin-1');
      expect(result.incident.bin.displayName, 'Plaza Bin');
      expect(
          result.incident.sensorType, 'Time-of-Flight (ToF) Fullness Sensor');
      expect(result.incident.issueDescription, 'naapaw na');
      expect(result.incident.severity, 'Medium');
      expect(result.incident.status, 'Pending');
      expect(result.incident.createdAt, DateTime.parse('2026-09-09T01:00:00Z'));
      expect(result.incident.updatedAt, DateTime.parse('2026-09-09T01:01:00Z'));
    });

    test('submits every exact severity and rejects noncanonical values',
        () async {
      final requests = <RequestOptions>[];
      final repository = ApiSensorIncidentRepository(
        apiClient: ApiClient(dio: _sensorDio(requests)),
      );

      for (final severity in SensorIncidentSeverities.values) {
        await repository.createIncident(
          binId: 'mongo-bin-1',
          issueDescription: 'Sensor problem',
          severity: severity,
        );
      }
      expect(
        requests.map((request) => request.data['severity']),
        ['Low', 'Medium', 'High', 'Critical'],
      );
      await expectLater(
        repository.createIncident(
          binId: 'mongo-bin-1',
          issueDescription: 'Sensor problem',
          severity: 'high',
        ),
        throwsArgumentError,
      );
    });

    test('history parses all statuses and optional resolution fields',
        () async {
      final requests = <RequestOptions>[];
      final repository = ApiSensorIncidentRepository(
        apiClient: ApiClient(dio: _sensorDio(requests, history: true)),
      );

      final incidents = await repository.fetchMyIncidents();

      expect(requests.single.method, 'GET');
      expect(requests.single.path, '/sensor-reports/my-reports');
      expect(
        incidents.map((incident) => incident.status),
        ['Pending', 'In Progress', 'Resolved', 'Dismissed'],
      );
      expect(incidents[2].resolutionNotes, 'Sensor replaced.');
      expect(incidents[2].resolvedAt, DateTime.parse('2026-09-09T04:00:00Z'));
    });
  });

  group('Phase 9 Maintenance warning', () {
    test('is required only for High and Critical', () {
      expect(SensorIncidentFormScreen.requiresMaintenanceConfirmation('Low'),
          isFalse);
      expect(SensorIncidentFormScreen.requiresMaintenanceConfirmation('Medium'),
          isFalse);
      expect(SensorIncidentFormScreen.requiresMaintenanceConfirmation('High'),
          isTrue);
      expect(
          SensorIncidentFormScreen.requiresMaintenanceConfirmation('Critical'),
          isTrue);
    });

    testWidgets('High severity shows warning before network submission',
        (tester) async {
      final repository = _FakeSensorIncidentRepository();
      await tester.pumpWidget(MaterialApp(
        home: SensorIncidentFormScreen(
          bin: const RecyTechBin(
            binId: 'mongo-bin-1',
            binName: 'Plaza Bin',
            location: 'Town Plaza',
          ),
          repository: repository,
        ),
      ));

      await tester.enterText(
        find.byKey(const Key('incident-description')),
        'Intermittent readings',
      );
      await tester.tap(find.byKey(const Key('incident-severity')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('High').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('report-incident-submit')));
      await tester.pumpAndSettle();

      expect(find.textContaining('place the bin in Maintenance status'),
          findsOneWidget);
      expect(repository.submissions, isEmpty);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(repository.submissions, isEmpty);
    });
  });

  group('Phase 9 cross-role request foundation', () {
    testWidgets('Partner Request Collection action reaches shared repository',
        (tester) async {
      final repository = _FakeCollectionRequestRepository();
      await tester.pumpWidget(ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (_, __) => MaterialApp(
          home: CollectionRequestFormScreen(
            bin: const RecyTechBin(
              databaseId: 'mongo-bin-1',
              binId: 'BIN-001',
              binName: 'Plaza Bin',
              location: 'Town Plaza',
            ),
            repository: repository,
          ),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Submit Request'),
        200,
        scrollable: _formScrollable(),
      );

      await tester.tap(find.text('Submit Request'));
      await tester.pumpAndSettle();

      expect(repository.binIds, ['mongo-bin-1']);
    });

    testWidgets('Partner Request Collection falls back to public binId only',
        (tester) async {
      final repository = _FakeCollectionRequestRepository();
      await tester.pumpWidget(ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (_, __) => MaterialApp(
          home: CollectionRequestFormScreen(
            bin: const RecyTechBin(
              binId: 'BIN-001',
              binName: 'NU Trash Org',
              location: 'Pinned at 14.6047, 120.9942',
              recyclingCenterId: 'recycling-center-1',
            ),
            repository: repository,
          ),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Submit Request'),
        200,
        scrollable: _formScrollable(),
      );

      await tester.tap(find.text('Submit Request'));
      await tester.pumpAndSettle();

      expect(repository.binIds, ['BIN-001']);
      expect(repository.binIds, isNot(contains('recycling-center-1')));
    });

    test('Partner request reuses Phase 4 and preserves request ID', () async {
      final requests = <RequestOptions>[];
      final repository = ApiCollectionRequestRepository(
        apiClient: ApiClient(dio: _crossRoleDio(requests)),
      );

      final created = await repository.createCollectionRequest(
        lguId: 'partner-profile-1',
        binId: 'mongo-bin-1',
        binLocation: 'Town Plaza',
        fillPercentage: 90,
        fullnessStatus: 'full',
        requestedAt: DateTime.parse('2026-09-09T01:00:00Z'),
      );

      expect(requests.single.path, '/requests');
      expect(
        requests.any((request) =>
            request.method == 'POST' &&
            request.path == '/partner/collection-requests'),
        isFalse,
      );
      expect(requests.single.data, {'binId': 'mongo-bin-1'});
      for (final forbidden in const {
        'partnerOrgId',
        'partnerOrganizationId',
        'lguId',
        'userId',
        'profileId',
      }) {
        expect(requests.single.data, isNot(contains(forbidden)));
      }
      expect(created.id, 'request-9');
      expect(created.binId, 'mongo-bin-1');
      expect(created.status, 'assigned');
    });

    test('maps visible Remarks to API notes without extra fields', () async {
      final requests = <RequestOptions>[];
      final repository = ApiCollectionRequestRepository(
        apiClient: ApiClient(dio: _crossRoleDio(requests)),
      );

      await repository.createCollectionRequest(
        lguId: 'partner-profile-1',
        binId: 'mongo-bin-1',
        binLocation: 'Town Plaza',
        fillPercentage: 100,
        fullnessStatus: 'full',
        requestedAt: DateTime.parse('2026-09-09T01:00:00Z'),
        remarks: 'Collect before noon.',
      );

      expect(requests.single.data, {
        'binId': 'mongo-bin-1',
        'notes': 'Collect before noon.',
      });
      expect(requests.single.data, isNot(contains('remarks')));
      expect(requests.single.data, isNot(contains('bin')));
      expect(requests.single.data, isNot(contains('requestType')));
      expect(requests.single.data, isNot(contains('scheduledDate')));
    });

    test('preserves a safe backend validation message', () async {
      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) => handler.reject(
          DioException(
            requestOptions: options,
            response: Response(
              requestOptions: options,
              statusCode: 400,
              data: {'message': 'Notes are required for this request.'},
            ),
            type: DioExceptionType.badResponse,
          ),
        ),
      ));
      final repository = ApiCollectionRequestRepository(
        apiClient: ApiClient(dio: dio),
      );

      await expectLater(
        repository.createCollectionRequest(
          lguId: 'partner-profile-1',
          binId: 'mongo-bin-1',
          binLocation: 'Town Plaza',
          fillPercentage: 100,
          fullnessStatus: 'full',
          requestedAt: DateTime.parse('2026-09-09T01:00:00Z'),
        ),
        throwsA(
          isA<CollectionRequestException>().having(
            (error) => error.message,
            'message',
            'Notes are required for this request.',
          ),
        ),
      );
    });

    test('Collector trusts backend-scoped jobs and keeps exact request ID',
        () async {
      final requests = <RequestOptions>[];
      final repository = CollectorRepository(
        api: CollectorApi(
          apiClient: ApiClient(dio: _crossRoleDio(requests)),
        ),
      );

      final jobs = await repository.fetchAssignedJobs(
        collectorId: 'wrong-id-is-not-used-for-local-filtering',
      );

      expect(requests.single.path, '/collectors/jobs');
      expect(requests.single.queryParameters, {'status': 'active'});
      expect(jobs.single.id, 'request-9');
      expect(jobs.single.assignedCollectorId, 'collector-profile-1');
      expect(jobs.single.partnerOrganizationName, 'Green Municipality');
    });
  });

  group('Phase 9 Household reward receipt foundation', () {
    test('projected points remain pending and never become local credit', () {
      final pending = DropOffRecord.fromJson({
        '_id': 'drop-1',
        'binId': 'bin-1',
        'status': 'pending',
        'pointsAwarded': 0,
        'projectedPoints': 50,
        'createdAt': '2026-09-09T01:00:00Z',
      });

      expect(pending.status, 'pending');
      expect(pending.pointsAwarded, 0);
      expect(pending.pointsProjected, 50);
      expect(pending.rewardLabel, isNot(contains('+50')));
    });

    test('approved points and profile balance remain backend-authoritative',
        () {
      final approved = DropOffRecord.fromJson({
        '_id': 'drop-1',
        'binId': 'bin-1',
        'status': 'approved',
        'pointsAwarded': 25,
        'projectedPoints': 50,
        'transactionId': 'transaction-1',
        'createdAt': '2026-09-09T01:00:00Z',
      });
      final profile = UnifiedProfile.fromJson({
        'user': {
          '_id': 'user-1',
          'role': 'household',
          'email': 'household@example.test',
        },
        'resident': {'_id': 'resident-1', 'pointsBalance': 125},
      });

      expect(approved.status, 'approved');
      expect(approved.pointsAwarded, 25);
      expect(approved.pointsProjected, 50);
      expect(profile.pointsBalance, 125);
      expect(profile.profileId, 'resident-1');
    });

    test('reuses transaction history and parses drop-off traceability',
        () async {
      final requests = <RequestOptions>[];
      final repository = ApiDropOffRepository(
        apiClient: ApiClient(dio: _crossRoleDio(requests)),
      );

      final transactions = await repository.getMyRewards();

      expect(ApiEndpoints.myTransactions, '/transactions/my');
      expect(requests.single.path, '/transactions/my');
      expect(transactions.single.id, 'transaction-1');
      expect(transactions.single.dropOffId, 'drop-1');
      expect(transactions.single.rewardPoints, 25);
    });
  });
}

Dio _sensorDio(List<RequestOptions> requests, {bool history = false}) {
  final dio = Dio(BaseOptions(headers: const {'Authorization': 'Bearer test'}));
  dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
    requests.add(options);
    if (history) {
      final statuses = ['Pending', 'In Progress', 'Resolved', 'Dismissed'];
      handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: {
          'success': true,
          'count': statuses.length,
          'data': [
            for (var index = 0; index < statuses.length; index++)
              {
                ..._incidentJson(
                  severity: index == 3 ? 'Critical' : 'Medium',
                  status: statuses[index],
                ),
                '_id': 'incident-${index + 1}',
                if (statuses[index] == 'Resolved')
                  'resolutionNotes': 'Sensor replaced.',
                if (statuses[index] == 'Resolved')
                  'resolvedAt': '2026-09-09T04:00:00Z',
              },
          ],
        },
      ));
      return;
    }
    final body = (options.data as Map).cast<String, dynamic>();
    handler.resolve(Response(
      requestOptions: options,
      statusCode: 201,
      data: {
        'success': true,
        'message': 'Sensor malfunction report submitted successfully.',
        'data': _incidentJson(
          severity: body['severity'].toString(),
          status: 'Pending',
          description: body['issueDescription'].toString(),
        ),
      },
    ));
  }));
  return dio;
}

Map<String, dynamic> _incidentJson({
  required String severity,
  required String status,
  String description = 'Reading is frozen.',
}) =>
    {
      '_id': 'incident-1',
      'binId': {
        '_id': 'mongo-bin-1',
        'name': 'Plaza Bin',
        'address': 'Town Plaza',
        'status': 'Operational',
      },
      'sensorType': 'Time-of-Flight (ToF) Fullness Sensor',
      'issueDescription': description,
      'severity': severity,
      'status': status,
      'createdAt': '2026-09-09T01:00:00Z',
      'updatedAt': '2026-09-09T01:01:00Z',
    };

Dio _crossRoleDio(List<RequestOptions> requests) {
  final dio = Dio(BaseOptions(headers: const {'Authorization': 'Bearer test'}));
  dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
    requests.add(options);
    dynamic data;
    if (options.path == '/requests') {
      data = {'request': _requestJson()};
    } else if (options.path == '/collectors/jobs') {
      data = {
        'jobs': [_requestJson()]
      };
    } else if (options.path == '/transactions/my') {
      data = {
        'transactions': [
          {
            '_id': 'transaction-1',
            'dropOff': {'_id': 'drop-1'},
            'pointsAwarded': 25,
            'status': 'completed',
            'createdAt': '2026-09-09T03:00:00Z',
          }
        ],
      };
    } else {
      data = <String, dynamic>{};
    }
    handler.resolve(Response(requestOptions: options, data: data));
  }));
  return dio;
}

Map<String, dynamic> _requestJson() => {
      '_id': 'request-9',
      'status': 'assigned',
      'requestType': 'bin_collection',
      'createdAt': '2026-09-09T01:00:00Z',
      'bin': {
        '_id': 'mongo-bin-1',
        'name': 'Plaza Bin',
        'address': 'Town Plaza',
      },
      'lgu': {'_id': 'partner-profile-1', 'name': 'Green Municipality'},
      'assignedCollector': {
        '_id': 'collector-profile-1',
        'firstName': 'Casey',
        'lastName': 'Collector',
      },
    };

Finder _formScrollable() {
  return find.byWidgetPredicate(
    (widget) => widget is Scrollable && widget.restorationId != 'editable',
  );
}

class _FakeSensorIncidentRepository implements SensorIncidentRepository {
  final submissions = <String>[];

  @override
  Future<SensorIncidentSubmissionResult> createIncident({
    required String binId,
    required String issueDescription,
    String severity = SensorIncidentSeverities.medium,
  }) async {
    submissions.add(severity);
    return SensorIncidentSubmissionResult(
      success: true,
      message: 'Reported',
      incident: SensorIncident.fromJson(
        _incidentJson(severity: severity, status: 'Pending'),
      ),
    );
  }

  @override
  Future<List<SensorIncident>> fetchMyIncidents() async => const [];
}

class _FakeCollectionRequestRepository implements CollectionRequestRepository {
  final binIds = <String>[];

  @override
  Future<CollectionRequestSummary> createCollectionRequest({
    required String lguId,
    required String binId,
    required String binLocation,
    required double? fillPercentage,
    required String fullnessStatus,
    required DateTime requestedAt,
    String? remarks,
  }) async {
    binIds.add(binId);
    return CollectionRequestSummary.fromJson(_requestJson());
  }

  @override
  Future<List<CollectionRequestSummary>> fetchCollectionRequests() async =>
      const [];
}
