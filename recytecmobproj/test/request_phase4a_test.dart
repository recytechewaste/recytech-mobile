import 'package:flutter_test/flutter_test.dart';
import 'package:recytecmobproj/core/constants/app_constants.dart';
import 'package:recytecmobproj/core/network/api_endpoints.dart';
import 'package:recytecmobproj/core/network/api_exceptions.dart';
import 'package:recytecmobproj/data/datasources/request_api.dart';
import 'package:recytecmobproj/data/datasources/collector_api.dart';
import 'package:recytecmobproj/data/models/bin_monitoring_models.dart';
import 'package:recytecmobproj/data/models/collector_job_model.dart';
import 'package:recytecmobproj/data/repositories/collection_request_repository.dart';
import 'package:recytecmobproj/data/repositories/collector_repository.dart';

class FakeRequestApi extends RequestApi {
  FakeRequestApi({required this.page, required this.detail});

  final RequestListResponse page;
  final Map<String, dynamic> detail;
  int listCalls = 0;
  int detailCalls = 0;

  @override
  Future<RequestListResponse> fetchRequests({
    int? page,
    int? limit,
    String? status,
    String? search,
  }) async {
    listCalls += 1;
    return this.page;
  }

  @override
  Future<Map<String, dynamic>> fetchRequest(String requestId) async {
    detailCalls += 1;
    return detail;
  }
}

class Phase4CollectorApi extends CollectorApi {
  Phase4CollectorApi(this.jobs);
  final List<Map<String, dynamic>> jobs;

  @override
  Future<List<Map<String, dynamic>>> fetchJobs({String? status}) async => jobs;
}

Map<String, dynamic> canonicalRequest({String status = 'assigned'}) => {
      '_id': 'request-1',
      'status': status,
      'createdAt': '2026-09-08T01:00:00.000Z',
      'scheduledDate': '2026-09-09T02:00:00.000Z',
      'notes': 'Collect before noon.',
      'requestType': 'bin_collection',
      'bin': {
        '_id': 'bin-1',
        'binCode': 'BIN-001',
        'name': 'Municipal Hall Bin',
        'location': {'address': 'Municipal Hall'},
      },
      'lgu': {
        '_id': 'partner-1',
        'name': 'Green Municipality',
      },
      'assignedCollector': {
        '_id': 'collector-1',
        'firstName': 'Juan',
        'lastName': 'Collector',
      },
    };

void main() {
  test('canonical request paths are /requests and /requests/:id', () {
    expect(ApiEndpoints.requests, '/requests');
    expect(ApiEndpoints.requestById('request-1'), '/requests/request-1');
  });

  test('request list parser requires and preserves the canonical envelope', () {
    final response = RequestListResponse.fromJson({
      'requests': [canonicalRequest()],
      'totalRequests': 1,
      'totalPages': 1,
      'currentPage': 1,
    });

    expect(response.requests, hasLength(1));
    expect(response.totalRequests, 1);
    expect(response.totalPages, 1);
    expect(response.currentPage, 1);
    expect(
      () => RequestListResponse.fromJson([canonicalRequest()]),
      throwsA(isA<ApiException>()),
    );
  });

  test('all canonical and compatibility statuses normalize once', () {
    for (final status in RequestStatuses.values) {
      expect(RequestStatuses.normalize(status), status);
      expect(RequestStatuses.normalize(status.toUpperCase()), status);
    }
    expect(RequestStatuses.normalize('in-progress'), 'in_progress');
    expect(RequestStatuses.normalize('in-transit'), 'in_transit');
    expect(RequestStatuses.normalize('Completed'), 'completed');
  });

  test('Partner summary parses populated bin, lgu, and collector', () {
    final request = CollectionRequestSummary.fromJson(canonicalRequest());

    expect(request.id, 'request-1');
    expect(request.status, RequestStatuses.assigned);
    expect(request.binId, 'bin-1');
    expect(request.binName, 'Municipal Hall Bin');
    expect(request.location, 'Municipal Hall');
    expect(request.lguId, 'partner-1');
    expect(request.partnerOrganizationName, 'Green Municipality');
    expect(request.assignedCollectorId, 'collector-1');
    expect(request.assignedCollectorName, 'Juan Collector');
    expect(request.requestType, 'bin_collection');
    expect(request.remarks, 'Collect before noon.');
    expect(request.scheduledDate, DateTime.parse('2026-09-09T02:00:00.000Z'));
  });

  test('Collector model parses canonical populated request detail', () {
    final job = CollectorJob.fromJson(canonicalRequest(status: 'in-transit'));

    expect(job.id, 'request-1');
    expect(job.status, RequestStatuses.inTransit);
    expect(job.binCode, 'BIN-001');
    expect(job.binName, 'Municipal Hall Bin');
    expect(job.location, 'Municipal Hall');
    expect(job.partnerOrganizationName, 'Green Municipality');
    expect(job.assignedCollectorId, 'collector-1');
    expect(job.assignedCollector, 'Juan Collector');
    expect(job.requestType, 'bin_collection');
    expect(job.remarks, 'Collect before noon.');
  });

  test('Partner and Collector repositories consume the backend-scoped page',
      () async {
    final api = FakeRequestApi(
      page: RequestListResponse(
        requests: [canonicalRequest()],
        totalRequests: 1,
        totalPages: 1,
        currentPage: 1,
      ),
      detail: canonicalRequest(),
    );
    final partner = ApiCollectionRequestRepository(requestApi: api);
    final collector = CollectorRepository(
      requestApi: api,
      api: Phase4CollectorApi([canonicalRequest()]),
    );

    expect(await partner.fetchCollectionRequests(), hasLength(1));
    final assigned = await collector.fetchAssignedJobs(
      collectorId: 'different-user-id',
      collectorName: 'Different Name',
      collectorEmail: 'different@example.com',
    );
    expect(assigned, hasLength(1));
    expect(api.listCalls, 1);
  });

  test('request detail is fetched from the canonical detail API', () async {
    final api = FakeRequestApi(
      page: const RequestListResponse(
        requests: [],
        totalRequests: 0,
        totalPages: 0,
        currentPage: 1,
      ),
      detail: canonicalRequest(status: 'arrived'),
    );
    final repository = CollectorRepository(requestApi: api);

    final detail = await repository.fetchRequestDetail('request-1');

    expect(api.detailCalls, 1);
    expect(detail.id, 'request-1');
    expect(detail.status, RequestStatuses.arrived);
  });
}
