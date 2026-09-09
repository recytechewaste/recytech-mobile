import '../../core/constants/app_constants.dart';
import '../datasources/collector_api.dart';
import '../datasources/request_api.dart';
import '../models/collector_job_model.dart';
import '../models/collector_profile_model.dart';

class CollectorRepository {
  CollectorRepository({CollectorApi? api, RequestApi? requestApi})
      : _api = api ?? CollectorApi(),
        _requestApi = requestApi ?? RequestApi();

  static const completionContractConflict =
      'WEB CONTRACT CONFLICT — COLLECTEDWASTE SCHEMA REQUIRED';

  final CollectorApi _api;
  final RequestApi _requestApi;

  Future<CollectorProfile> fetchProfile() async =>
      CollectorProfile.fromJson(await _api.fetchMe());

  Future<CollectorProfile> updateDutyStatus(String status) async {
    if (status != 'Active' && status != 'Inactive') {
      throw ArgumentError.value(status, 'status', 'Must be Active or Inactive');
    }
    await _api.updateDutyStatus(status);
    return fetchProfile();
  }

  Future<List<CollectorJob>> fetchAssignedJobs({
    String? collectorId,
    String? collectorName,
    String? collectorEmail,
  }) =>
      _fetchJobs('active');

  Future<List<CollectorJob>> fetchCompletedJobs({
    String? collectorId,
    String? collectorName,
    String? collectorEmail,
  }) =>
      _fetchJobs('completed');

  Future<List<CollectorJob>> _fetchJobs(String status) async {
    final jobs = await _api.fetchJobs(status: status);
    return jobs
        .map(CollectorJob.fromJson)
        .where((job) => job.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<CollectorStats> fetchStats() async =>
      CollectorStats.fromJson(await _api.fetchStats());

  Future<CollectorJob> fetchRequestDetail(String requestId) async {
    final response = await _requestApi.fetchRequest(requestId);
    final nested = response['request'] ?? response['job'] ?? response['data'];
    return CollectorJob.fromJson(
      nested is Map ? nested.cast<String, dynamic>() : response,
    );
  }

  Future<CollectorJob> updateJobStatus({
    required String requestId,
    required String status,
    String? currentStatus,
    String? collectorId,
    String? collectorName,
    String? collectorEmail,
  }) async {
    final canonical = status.trim().toLowerCase();
    if (!CollectorJobStatuses.isOperationalUpdate(canonical) ||
        status != canonical) {
      throw ArgumentError.value(status, 'status', 'Unsupported status update');
    }
    if (currentStatus != null &&
        !CollectorJobStatuses.canTransition(currentStatus, canonical)) {
      throw StateError('Unsupported collector status transition.');
    }
    final updated = await _api.updateRequestStatus(requestId, canonical);
    return CollectorJob.fromJson(updated);
  }

  Future<Never> completeCollection({required String requestId}) async {
    throw StateError(completionContractConflict);
  }
}
