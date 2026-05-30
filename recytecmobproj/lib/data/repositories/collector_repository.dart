import '../datasources/collector_api.dart';
import '../models/collector_job_model.dart';

class CollectorRepository {
  final CollectorApi _api;

  CollectorRepository({CollectorApi? api}) : _api = api ?? CollectorApi();

  Future<List<CollectorJob>> fetchAvailableJobs() async {
    final jobs = await _fetchJobs();

    final availableJobs = jobs
        .where((job) => job.id.isNotEmpty && job.isApproved)
        .toList()
      ..sort(_oldestFirst);

    return availableJobs;
  }

  Future<List<CollectorJob>> fetchAssignedJobs() async {
    final jobs = await _fetchJobs();

    return jobs
        .where(
          (job) =>
              job.id.isNotEmpty &&
              !job.isRejected &&
              !job.isCompleted &&
              (job.isApproved || job.isInTransit),
        )
        .toList()
      ..sort(_oldestFirst);
  }

  Future<List<CollectorJob>> _fetchJobs() async {
    final list = await _api.fetchJobs();

    return list
        .whereType<Map>()
        .map((e) => CollectorJob.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<CollectorJob> acceptJob({
    required String requestId,
    String? collectorId,
    String? collectorName,
    String? collectorEmail,
  }) {
    return updateJobStatus(
      requestId: requestId,
      status: 'In-Transit',
      collectorId: collectorId,
      collectorName: collectorName,
      collectorEmail: collectorEmail,
    );
  }

  Future<CollectorJob> updateJobStatus({
    required String requestId,
    required String status,
    String? collectorId,
    String? collectorName,
    String? collectorEmail,
  }) async {
    final payload = <String, dynamic>{
      'status': status,
    };

    final trimmedCollectorId = collectorId?.trim() ?? '';
    final trimmedCollectorName = collectorName?.trim() ?? '';
    final trimmedCollectorEmail = collectorEmail?.trim() ?? '';

    if (trimmedCollectorId.isNotEmpty) {
      payload['assignedCollector'] = trimmedCollectorId;
      payload['assignedCollectorId'] = trimmedCollectorId;
    }

    if (trimmedCollectorName.isNotEmpty) {
      payload['assignedCollectorName'] = trimmedCollectorName;
      payload['collectorName'] = trimmedCollectorName;
    }

    if (trimmedCollectorEmail.isNotEmpty) {
      payload['collectorEmail'] = trimmedCollectorEmail;
    }

    final updated = await _api.updateRequest(
      requestId,
      payload,
    );

    return CollectorJob.fromJson(updated);
  }

  int _oldestFirst(CollectorJob a, CollectorJob b) {
    final aDate = DateTime.tryParse(a.createdAt);
    final bDate = DateTime.tryParse(b.createdAt);

    if (aDate != null && bDate != null) {
      return aDate.compareTo(bDate);
    }

    if (aDate != null) return -1;
    if (bDate != null) return 1;

    return a.createdAt.compareTo(b.createdAt);
  }
}
