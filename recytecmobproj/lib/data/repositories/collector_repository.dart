import '../datasources/collector_api.dart';
import '../models/collector_job_model.dart';

class CollectorRepository {
  final CollectorApi _api;

  CollectorRepository({CollectorApi? api}) : _api = api ?? CollectorApi();

  Future<List<CollectorJob>> fetchAvailableJobs() async {
    final jobs = await _fetchQueue();
    return jobs.where((job) => job.isAvailableForAssignment).toList();
  }

  Future<List<CollectorJob>> fetchAssignedJobs({
    String? collectorId,
    String? collectorName,
    String? collectorEmail,
  }) async {
    final currentJob = await _api.fetchCurrentJob();
    if (currentJob == null) return <CollectorJob>[];

    final job = CollectorJob.fromJson(currentJob);
    return job.id.isEmpty ? <CollectorJob>[] : <CollectorJob>[job];
  }

  Future<List<CollectorJob>> fetchCompletedJobs({
    String? collectorId,
    String? collectorName,
    String? collectorEmail,
  }) async {
    final jobs = await _fetchQueue();
    return jobs
        .where(
          (job) =>
              job.id.isNotEmpty &&
              job.isCompleted &&
              job.isAssignedTo(
                collectorId: collectorId,
                collectorName: collectorName,
                collectorEmail: collectorEmail,
              ),
        )
        .toList()
      ..sort((a, b) => _scheduledThenOldest(b, a));
  }

  Future<List<CollectorJob>> _fetchQueue() async {
    final list = await _api.fetchQueue();

    return list
        .whereType<Map>()
        .map((e) => CollectorJob.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<CollectorJob> startCollection({
    required String requestId,
  }) async {
    final updated = await _api.startCollectionRequest(requestId);
    return CollectorJob.fromJson(updated);
  }

  Future<CollectorJob> startNextCollection() async {
    final updated = await _api.startNextCollection();
    return CollectorJob.fromJson(updated);
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

  int _scheduledThenOldest(CollectorJob a, CollectorJob b) {
    final aDate = a.scheduledDate ?? a.createdDate;
    final bDate = b.scheduledDate ?? b.createdDate;

    if (aDate != null && bDate != null) {
      return aDate.compareTo(bDate);
    }

    if (aDate != null) return -1;
    if (bDate != null) return 1;

    return _oldestFirst(a, b);
  }
}
