import '../datasources/collector_api.dart';
import '../models/collected_item_model.dart';
import '../models/collector_job_model.dart';

abstract class CollectionCompletionRepository {
  Future<CollectorJob> submitCollectionReport(CollectionReportDraft report);
}

class ApiCollectionCompletionRepository
    implements CollectionCompletionRepository {
  ApiCollectionCompletionRepository({CollectorApi? api})
      : _api = api ?? CollectorApi();

  final CollectorApi _api;

  @override
  Future<CollectorJob> submitCollectionReport(
    CollectionReportDraft report,
  ) async {
    final items = report.completionItems;
    if (items.any((item) => !item.isValid)) {
      throw const FormatException(
        'Each collected item requires category, non-negative quantity, and unit.',
      );
    }
    final response = await _api.completeRequest(
      report.assignmentId,
      collectedWaste: items.isEmpty
          ? null
          : items.map((item) => item.toJson()).toList(growable: false),
      notes: report.completionNotes,
    );
    return CollectorJob.fromJson(response);
  }
}
