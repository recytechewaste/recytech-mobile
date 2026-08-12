import '../../core/constants/app_constants.dart';
import '../models/bin_monitoring_models.dart';

abstract class CollectionRequestRepository {
  Future<List<CollectionRequestSummary>> fetchCollectionRequests();

  Future<CollectionRequestSummary> createCollectionRequest({
    required String lguId,
    required String binId,
    required String binLocation,
    required double? fillPercentage,
    required String fullnessStatus,
    required DateTime requestedAt,
    String? remarks,
  });
}

/// Temporary mock repository.
///
/// Backend work still needed:
/// - GET /api/lgu/collection-requests
/// - POST /api/lgu/collection-requests
/// - Include bin ToF reading snapshot fields in request payload/response.
class MockCollectionRequestRepository implements CollectionRequestRepository {
  static final List<CollectionRequestSummary> _requests = [
    CollectionRequestSummary(
      id: 'CR-1007',
      lguId: 'LGU-DEMO-001',
      binId: 'BIN-LGU-001',
      location: 'Municipal Hall East Entrance',
      fillPercentage: 92,
      fullnessStatus: FullnessStatuses.full,
      status: CollectionRequestStatuses.collectorAssigned,
      requestedAt: DateTime(2026, 8, 3, 10, 20),
      reason: 'Full bin',
      remarks: 'Prioritize before market day.',
      assignedCollectorName: 'Juan Collector',
    ),
    CollectionRequestSummary(
      id: 'CR-1006',
      lguId: 'LGU-DEMO-001',
      binId: 'BIN-LGU-003',
      location: 'Barangay San Isidro Covered Court',
      fillPercentage: null,
      fullnessStatus: FullnessStatuses.requiresInspection,
      status: CollectionRequestStatuses.pending,
      requestedAt: DateTime(2026, 8, 2, 15, 45),
      reason: 'Inspection requested',
      remarks: 'Sensor reading unavailable.',
    ),
    CollectionRequestSummary(
      id: 'CR-1005',
      lguId: 'LGU-DEMO-001',
      binId: 'BIN-LGU-004',
      location: 'City Library South Wing',
      fillPercentage: 74,
      fullnessStatus: FullnessStatuses.nearlyFull,
      status: CollectionRequestStatuses.completed,
      requestedAt: DateTime(2026, 7, 29, 9, 5),
      reason: 'Nearly full',
      assignedCollectorName: 'Ana Collector',
    ),
  ];

  @override
  Future<List<CollectionRequestSummary>> fetchCollectionRequests() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final copy = List<CollectionRequestSummary>.from(_requests);
    copy.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
    return copy;
  }

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
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final request = CollectionRequestSummary(
      id: 'CR-${1008 + _requests.length}',
      lguId: lguId,
      binId: binId,
      location: binLocation,
      fillPercentage: fillPercentage,
      fullnessStatus: fullnessStatus,
      status: CollectionRequestStatuses.pending,
      requestedAt: requestedAt,
      reason: FullnessStatuses.label(fullnessStatus),
      remarks: remarks,
    );
    _requests.insert(0, request);
    return request;
  }

  static CollectionRequestSummary? activeRequestForBin(String binId) {
    for (final request in _requests) {
      if (request.binId == binId &&
          CollectionRequestStatuses.isActive(request.status)) {
        return request;
      }
    }
    return null;
  }
}
