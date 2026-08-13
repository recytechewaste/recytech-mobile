import '../../core/constants/app_constants.dart';
import '../models/bin_monitoring_models.dart';
import 'collection_request_repository.dart';

abstract class LguBinRepository {
  Future<List<RecyTechBin>> fetchAssignedBins();
  Future<RecyTechBin> fetchBin(String binId);
  Future<BinMonitoringData> fetchMonitoring(String binId);
}

abstract class BinMonitoringService implements LguBinRepository {
  @Deprecated('Legacy camera/deposit workflow detached from routed LGU UI.')
  Future<List<DepositEvent>> fetchDepositEvents(String binId);

  @Deprecated('Legacy camera/deposit workflow detached from routed LGU UI.')
  Future<DepositEvent> fetchDepositEvent(String eventId);

  @Deprecated('Legacy camera/deposit workflow detached from routed LGU UI.')
  Future<List<DepositEvent>> fetchCollectorAssignmentDepositEvents(
    String assignmentId,
  );

  @Deprecated('Use CollectionRequestRepository for LGU collection requests.')
  Future<CollectionRequestSummary> createCollectionRequest({
    required String binId,
    required String reason,
    required String priority,
    String? notes,
  });

  @Deprecated('Use CollectionRequestRepository for LGU collection requests.')
  Future<List<CollectionRequestSummary>> fetchCollectionRequests();

  @Deprecated('Legacy collector completion report placeholder.')
  Future<void> submitCollectionReport(CollectionReport report);
}

/// Temporary mock repository for the LGU ToF monitoring UI.
///
/// Backend work still needed:
/// - GET /api/lgu/bins
/// - GET /api/lgu/bins/:binId
/// - GET /api/lgu/bins/:binId/monitoring
///
/// Expected data flow:
/// VL53L1X ToF sensor -> XIAO ESP32-S3 -> Wi-Fi -> backend -> Flutter.
class MockBinMonitoringService implements BinMonitoringService {
  MockBinMonitoringService();

  final List<RecyTechBin> _bins = [
    RecyTechBin(
      binId: 'BIN-LGU-001',
      binName: 'Municipal Hall Bin',
      assignedLguId: 'LGU-DEMO-001',
      location: 'Municipal Hall East Entrance',
      distanceCm: 8.5,
      fillPercentage: 92,
      fullnessStatus: FullnessStatuses.full,
      sensorStatus: SensorStatuses.online,
      controllerStatus: 'online',
      latitude: 14.5995,
      longitude: 120.9842,
      lastUpdatedAt: DateTime(2026, 8, 4, 9, 18),
      lastCollectionAt: DateTime(2026, 7, 30, 16, 10),
      activeCollectionRequest:
          MockCollectionRequestRepository.activeRequestForBin('BIN-LGU-001'),
    ),
    RecyTechBin(
      binId: 'BIN-LGU-002',
      binName: 'Public Market Bin',
      assignedLguId: 'LGU-DEMO-001',
      location: 'Public Market Gate 2',
      distanceCm: 31.4,
      fillPercentage: 46,
      fullnessStatus: FullnessStatuses.partiallyFilled,
      sensorStatus: SensorStatuses.delayedSync,
      controllerStatus: 'online',
      latitude: 14.6042,
      longitude: 120.9822,
      lastUpdatedAt: DateTime(2026, 8, 4, 8, 50),
      lastCollectionAt: DateTime(2026, 7, 28, 14, 30),
    ),
    RecyTechBin(
      binId: 'BIN-LGU-003',
      binName: 'Barangay Court Bin',
      assignedLguId: 'LGU-DEMO-001',
      location: 'Barangay San Isidro Covered Court',
      distanceCm: null,
      fillPercentage: null,
      fullnessStatus: FullnessStatuses.requiresInspection,
      sensorStatus: SensorStatuses.online,
      controllerStatus: 'requires_inspection',
      lastUpdatedAt: DateTime(2026, 8, 3, 17, 6),
      lastCollectionAt: DateTime(2026, 7, 25, 11, 5),
      activeCollectionRequest:
          MockCollectionRequestRepository.activeRequestForBin('BIN-LGU-003'),
    ),
    RecyTechBin(
      binId: 'BIN-LGU-004',
      binName: 'City Library Bin',
      assignedLguId: 'LGU-DEMO-001',
      location: 'City Library South Wing',
      distanceCm: 14.7,
      fillPercentage: 74,
      fullnessStatus: FullnessStatuses.nearlyFull,
      sensorStatus: SensorStatuses.offline,
      controllerStatus: 'offline',
      latitude: 14.6021,
      longitude: 120.9891,
      lastUpdatedAt: DateTime(2026, 8, 1, 11, 2),
      lastCollectionAt: DateTime(2026, 7, 29, 16, 35),
    ),
  ];

  @override
  Future<List<RecyTechBin>> fetchAssignedBins() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return List<RecyTechBin>.from(_bins);
  }

  @override
  Future<RecyTechBin> fetchBin(String binId) async {
    final bins = await fetchAssignedBins();
    return bins.firstWhere(
      (bin) => bin.binId == binId,
      orElse: () => bins.first,
    );
  }

  @override
  Future<BinMonitoringData> fetchMonitoring(String binId) async {
    final bin = await fetchBin(binId);
    return BinMonitoringData(
      binId: bin.binId,
      distanceCm: bin.distanceCm,
      fillPercentage: bin.fillPercentage,
      fullnessStatus: bin.fullnessStatus,
      sensorStatus: bin.sensorStatus,
      controllerStatus: bin.controllerStatus,
      activeCollectionRequest: bin.activeCollectionRequest,
      lastUpdatedAt: bin.lastUpdatedAt ?? DateTime.now(),
    );
  }

  @override
  Future<List<CollectionRequestSummary>> fetchCollectionRequests() {
    return MockCollectionRequestRepository().fetchCollectionRequests();
  }

  @override
  Future<CollectionRequestSummary> createCollectionRequest({
    required String binId,
    required String reason,
    required String priority,
    String? notes,
  }) async {
    final bin = await fetchBin(binId);
    return MockCollectionRequestRepository().createCollectionRequest(
      lguId: bin.assignedLguId ?? 'LGU-DEMO-001',
      binId: bin.binId,
      binLocation: bin.location,
      fillPercentage: bin.fillPercentage,
      fullnessStatus: bin.fullnessStatus,
      requestedAt: DateTime.now(),
      remarks: notes,
    );
  }

  @override
  Future<List<DepositEvent>> fetchDepositEvents(String binId) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return _legacyEvents.where((event) => event.binId == binId).toList()
      ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
  }

  @override
  Future<DepositEvent> fetchDepositEvent(String eventId) async {
    await Future<void>.delayed(const Duration(milliseconds: 160));
    return _legacyEvents.firstWhere(
      (event) => event.id == eventId,
      orElse: () => _legacyEvents.first,
    );
  }

  @override
  Future<List<DepositEvent>> fetchCollectorAssignmentDepositEvents(
    String assignmentId,
  ) {
    return fetchDepositEvents('BIN-LGU-001');
  }

  @override
  Future<void> submitCollectionReport(CollectionReport report) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }

  List<DepositEvent> get _legacyEvents => [
        DepositEvent(
          id: 'DEP-LEGACY-001',
          binId: 'BIN-LGU-001',
          cameraId: 'INLET-CAM-001',
          imageUrl: 'asset:assets/images/ai.png',
          capturedAt: DateTime(2026, 8, 4, 9, 12),
          detections: const [
            ObjectDetection(
              objectClass: 'smartphone',
              confidence: 0.91,
              mappedCategory: 'IT & Telecommunications',
              boundingBox: BoundingBox(x: 126, y: 88, width: 286, height: 318),
              modelVersion: 'recytech_yolov8_v1',
            ),
          ],
          status: 'Legacy recorded',
          requiresVerification: false,
          verificationStatus: 'Not required',
          createdAt: DateTime(2026, 8, 4, 9, 12),
          updatedAt: DateTime(2026, 8, 4, 9, 12),
        ),
      ];
}
