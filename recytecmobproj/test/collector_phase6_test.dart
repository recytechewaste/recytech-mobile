import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recytecmobproj/core/network/api_client.dart';
import 'package:recytecmobproj/core/network/api_endpoints.dart';
import 'package:recytecmobproj/data/datasources/collector_api.dart';
import 'package:recytecmobproj/data/models/collected_item_model.dart';
import 'package:recytecmobproj/data/models/collector_job_model.dart';
import 'package:recytecmobproj/data/models/collector_profile_model.dart';
import 'package:recytecmobproj/data/repositories/collector_repository.dart';

void main() {
  group('Phase 6 endpoint contract', () {
    test('uses Collector profile, status, jobs, stats, and completion paths',
        () {
      expect(ApiEndpoints.collectorsMe, '/collectors/me');
      expect(ApiEndpoints.collectorsStatus, '/collectors/status');
      expect(ApiEndpoints.collectorsJobs, '/collectors/jobs');
      expect(ApiEndpoints.collectorsStats, '/collectors/stats');
      expect(ApiEndpoints.completeRequest('R1'), '/requests/R1/complete');
    });

    test('calls exact methods, queries, and canonical payloads', () async {
      final requests = <RequestOptions>[];
      final api = CollectorApi(
        apiClient: ApiClient(dio: _recordingDio(requests)),
      );

      await api.fetchMe();
      await api.updateDutyStatus('Active');
      await api.updateDutyStatus('Inactive');
      await api.fetchJobs();
      await api.fetchJobs(status: 'active');
      await api.fetchJobs(status: 'completed');
      await api.fetchStats();
      await api.updateRequestStatus('R1', 'in_transit');
      await api.updateRequestStatus('R1', 'arrived');
      await api.updateRequestStatus('R1', 'in_progress');
      await api.completeRequest('R1', collectedWaste: const []);

      expect(requests[0].path, '/collectors/me');
      expect(requests[1].method, 'PATCH');
      expect(requests[1].data, {'status': 'Active'});
      expect(requests[2].data, {'status': 'Inactive'});
      expect(requests[3].queryParameters, isEmpty);
      expect(requests[4].queryParameters, {'status': 'active'});
      expect(requests[5].queryParameters, {'status': 'completed'});
      expect(requests[6].path, '/collectors/stats');
      expect(requests.skip(7).take(3).map((r) => r.data), [
        {'status': 'in_transit'},
        {'status': 'arrived'},
        {'status': 'in_progress'},
      ]);
      expect(requests[10].method, 'PATCH');
      expect(requests[10].path, '/requests/R1/complete');
      expect(requests[10].data, <String, dynamic>{});
      expect(requests.where((r) => r.path.contains('/bin')), isEmpty);
      expect(
          requests.any((r) => r.data is Map && r.data['status'] == 'accepted'),
          isFalse);
    });
  });

  group('Phase 6 parsing and guards', () {
    test('profile keeps User and Collector identities distinct', () {
      final profile = CollectorProfile.fromJson(_profileJson());
      expect(profile.profileId, 'collector-profile-1');
      expect(profile.userId, 'user-1');
      expect(profile.fullName, 'Juan Dela Cruz');
      expect(profile.vehiclePlate, 'COL-1234');
      expect(profile.vehicleType, 'Truck');
      expect(profile.status, 'Active');
      expect(profile.activeJobs, 2);
      expect(profile.completedJobs, 14);

      expect(
        CollectorProfile.fromJson({
          ..._profileJson(),
          'profile': {
            ..._profileJson()['profile'] as Map,
            'status': 'Inactive'
          },
        }).status,
        'Inactive',
      );
    });

    test('job parses detail and GeoJSON as longitude then latitude', () {
      final job = CollectorJob.fromJson(_jobJson(status: 'in_transit'));
      expect(job.id, 'request-1');
      expect(job.status, 'in_transit');
      expect(job.requestType, 'bin_collection');
      expect(job.binId, 'bin-1');
      expect(job.binName, 'Municipal Hall Bin');
      expect(job.location, 'Municipal Hall');
      expect(job.longitude, 121.0244);
      expect(job.latitude, 14.5547);
      expect(job.partnerOrganizationName, 'Green Municipality');
      expect(job.assignedCollectorId, 'collector-profile-1');
      expect(job.remarks, 'Collect before noon.');
    });

    test('stats renders only returned values', () {
      final stats = CollectorStats.fromJson({
        'completedCollections': 14,
        'totalItemsCollected': 42,
        'categoryTotals': {'laptop': 7},
      });
      expect(stats.values['completedCollections'], 14);
      expect(stats.values['totalItemsCollected'], 42);
      expect(stats.values['categoryTotals'], {'laptop': 7});
    });

    test('repository trusts backend-scoped active and completed lists',
        () async {
      final api = FakeCollectorApi();
      final repository = CollectorRepository(api: api);
      expect(await repository.fetchAssignedJobs(collectorEmail: 'wrong@x.test'),
          hasLength(1));
      expect(await repository.fetchCompletedJobs(collectorName: 'Wrong Name'),
          hasLength(1));
      expect(api.jobFilters, ['active', 'completed']);
    });

    test('only next canonical operational transition is submitted', () async {
      final api = FakeCollectorApi();
      final repository = CollectorRepository(api: api);
      await repository.updateJobStatus(
        requestId: 'R1',
        currentStatus: 'assigned',
        status: 'in_transit',
      );
      await repository.updateJobStatus(
        requestId: 'R1',
        currentStatus: 'in_transit',
        status: 'arrived',
      );
      await repository.updateJobStatus(
        requestId: 'R1',
        currentStatus: 'arrived',
        status: 'in_progress',
      );
      expect(api.submittedStatuses, ['in_transit', 'arrived', 'in_progress']);

      expect(
        () => repository.updateJobStatus(
          requestId: 'R1',
          currentStatus: 'assigned',
          status: 'accepted',
        ),
        throwsArgumentError,
      );
      expect(
        () => repository.updateJobStatus(
          requestId: 'R1',
          currentStatus: 'assigned',
          status: 'in_progress',
        ),
        throwsStateError,
      );
      expect(api.submittedStatuses, hasLength(3));
    });

    test('completion item uses only category quantity and unit', () {
      const item = CollectedWastePayloadItem(
        category: 'Battery',
        quantity: 0,
        unit: 'pcs',
      );
      expect(item.toJson(), {
        'category': 'Battery',
        'quantity': 0,
        'unit': 'pcs',
      });
    });
  });
}

class FakeCollectorApi extends CollectorApi {
  final jobFilters = <String?>[];
  final submittedStatuses = <String>[];

  @override
  Future<List<Map<String, dynamic>>> fetchJobs({String? status}) async {
    jobFilters.add(status);
    return [_jobJson(status: status == 'completed' ? 'completed' : 'assigned')];
  }

  @override
  Future<Map<String, dynamic>> updateRequestStatus(
      String requestId, String status) async {
    submittedStatuses.add(status);
    return _jobJson(status: status);
  }
}

Map<String, dynamic> _profileJson() => {
      'profile': {
        '_id': 'collector-profile-1',
        'firstName': 'Juan',
        'lastName': 'Dela Cruz',
        'vehiclePlate': 'COL-1234',
        'vehicleType': 'Truck',
        'status': 'Active',
      },
      'user': {
        '_id': 'user-1',
        'email': 'collector@recytech.com',
        'role': 'collector',
      },
      'stats': {'activeJobs': 2, 'completedJobs': 14},
    };

Map<String, dynamic> _jobJson({required String status}) => {
      '_id': 'request-1',
      'status': status,
      'requestType': 'bin_collection',
      'scheduledDate': '2026-09-09T02:00:00Z',
      'notes': 'Collect before noon.',
      'bin': {
        '_id': 'bin-1',
        'name': 'Municipal Hall Bin',
        'address': 'Municipal Hall',
        'location': {
          'address': 'Municipal Hall',
          'coordinates': [121.0244, 14.5547],
        },
      },
      'lgu': {'_id': 'partner-1', 'name': 'Green Municipality'},
      'assignedCollector': {
        '_id': 'collector-profile-1',
        'firstName': 'Juan',
        'lastName': 'Dela Cruz',
      },
    };

Dio _recordingDio(List<RequestOptions> requests) {
  final dio = Dio(BaseOptions(headers: const {'Authorization': 'Bearer test'}));
  dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
    requests.add(options);
    dynamic data = <String, dynamic>{};
    if (options.path == '/collectors/me') data = _profileJson();
    if (options.path == '/collectors/jobs') {
      data = {
        'jobs': [_jobJson(status: 'assigned')]
      };
    }
    if (options.path.startsWith('/requests/')) {
      data = {
        'request': _jobJson(status: options.data?['status'] ?? 'assigned')
      };
    }
    handler.resolve(Response(requestOptions: options, data: data));
  }));
  return dio;
}
