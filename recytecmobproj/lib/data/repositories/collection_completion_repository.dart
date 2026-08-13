import '../models/collected_item_model.dart';

abstract class CollectionCompletionRepository {
  Future<void> submitCollectionReport(CollectionReportDraft report);
  Future<List<CollectionReportDraft>> fetchCompletedReports();
}

/// Temporary completion boundary until the backend exposes collection reports.
///
/// Backend contract still needed:
/// POST /api/collector/collection-reports
/// Body: CollectionReportDraft.toJson(), including requestId, collectorId,
/// optional LGU/bin context, before/after evidence, confirmed item list,
/// confirmedCategorySummary, and totalQuantity. Collector-entered weight is
/// intentionally not part of the Phase 3 mobile contract.
/// GET /api/collector/collection-reports?collectorId=:id
class MockCollectionCompletionRepository
    implements CollectionCompletionRepository {
  static final List<CollectionReportDraft> _reports = <CollectionReportDraft>[];

  @override
  Future<void> submitCollectionReport(CollectionReportDraft report) async {
    await Future<void>.delayed(const Duration(milliseconds: 260));
    _reports.removeWhere((item) => item.assignmentId == report.assignmentId);
    _reports.add(report);
  }

  @override
  Future<List<CollectionReportDraft>> fetchCompletedReports() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return List<CollectionReportDraft>.from(_reports)
      ..sort((a, b) {
        final aDate = a.completedAt ?? a.startedAt;
        final bDate = b.completedAt ?? b.startedAt;
        return bDate.compareTo(aDate);
      });
  }
}
