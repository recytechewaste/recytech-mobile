import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/bin_monitoring_models.dart';
import 'collection_request_repository.dart';

abstract class LguBinRepository {
  Future<List<RecyTechBin>> fetchAssignedBins();
  Future<RecyTechBin> fetchBin(String binId);
  Future<BinMonitoringData> fetchMonitoring(String binId);
  Future<RecyTechBin> updateBinStatus({
    required String binId,
    required String status,
    double? fillLevelKg,
    String? notes,
  });
}

class ApiPartnerBinRepository implements LguBinRepository {
  ApiPartnerBinRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<List<RecyTechBin>> fetchAssignedBins() async {
    try {
      final response =
          await _apiClient.dio.get(ApiEndpoints.partnerOrganizationBins);
      _debugPartnerBinsResponse(
        statusCode: response.statusCode,
        body: response.data,
      );
      final items = _extractItems(response.data);
      return items
          .map((item) => RecyTechBin.fromJson(item.cast<String, dynamic>()))
          .toList(growable: false);
    } on DioException catch (error) {
      _debugPartnerBinsResponse(
        statusCode: error.response?.statusCode,
        body: error.response?.data,
      );
      rethrow;
    }
  }

  @override
  Future<RecyTechBin> fetchBin(String binId) async {
    final bins = await fetchAssignedBins();
    return bins.firstWhere(
      (bin) => bin.binId == binId || bin.apiId == binId,
      orElse: () => throw StateError('Assigned bin was not found.'),
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
      lastUpdatedAt: bin.lastUpdatedAt,
      activeCollectionRequest: bin.activeCollectionRequest,
    );
  }

  @override
  Future<RecyTechBin> updateBinStatus({
    required String binId,
    required String status,
    double? fillLevelKg,
    String? notes,
  }) async {
    if (!PartnerBinStatuses.isValid(status)) {
      throw ArgumentError.value(status, 'status', 'Unsupported bin status');
    }
    if (fillLevelKg != null && (!fillLevelKg.isFinite || fillLevelKg < 0)) {
      throw ArgumentError.value(
        fillLevelKg,
        'fillLevelKg',
        'Must be finite and non-negative',
      );
    }
    final response = await _apiClient.dio.patch(
      ApiEndpoints.partnerOrganizationBinStatus(binId),
      data: {
        'status': status,
        if (fillLevelKg != null) 'fillLevelKg': fillLevelKg,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
    );
    final value = _extractObject(response.data);
    if (value.isNotEmpty) return RecyTechBin.fromJson(value);
    return fetchBin(binId);
  }

  List<Map<dynamic, dynamic>> _extractItems(dynamic payload) {
    final dynamic items;
    if (payload is List) {
      items = payload;
    } else if (payload is Map) {
      items = payload['bins'] ??
          payload['data'] ??
          payload['items'] ??
          payload['results'];
    } else {
      throw const FormatException(
        'Partner bins response must be a list or an object containing a list.',
      );
    }

    if (items is! List) {
      throw const FormatException(
        'Partner bins response does not contain a bins list.',
      );
    }

    if (items.any((item) => item is! Map)) {
      throw const FormatException(
        'Partner bins response contains an invalid bin item.',
      );
    }

    return items.cast<Map<dynamic, dynamic>>();
  }

  void _debugPartnerBinsResponse({
    required int? statusCode,
    required dynamic body,
  }) {
    if (!kDebugMode) return;
    debugPrint('[PARTNER BINS] status=$statusCode');
    debugPrint('[PARTNER BINS] bodyType=${body.runtimeType}');
    debugPrint('[PARTNER BINS] body=${_sanitizedShape(body)}');
  }

  String _sanitizedShape(dynamic value) {
    if (value == null) return 'null';
    if (value is List) {
      final itemTypes =
          value.map((item) => item.runtimeType.toString()).toSet();
      return 'List(length=${value.length}, itemTypes=$itemTypes)';
    }
    if (value is Map) {
      final keys = value.keys.map((key) => key.toString()).toList()..sort();
      final fields = keys.map((key) {
        final fieldValue = value[key];
        if (fieldValue is List) return '$key=List(length=${fieldValue.length})';
        if (fieldValue is Map) {
          return '$key=Map(keys=${fieldValue.keys.length})';
        }
        return '$key=${fieldValue.runtimeType}';
      }).join(', ');
      return 'Map($fields)';
    }
    return value.runtimeType.toString();
  }

  Map<String, dynamic> _extractObject(dynamic payload) {
    if (payload is Map) {
      final map = payload.cast<String, dynamic>();
      final nested = map['bin'] ?? map['data'];
      if (nested is Map) return nested.cast<String, dynamic>();
      return map;
    }
    return <String, dynamic>{};
  }
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
      lastUpdatedAt: bin.lastUpdatedAt,
    );
  }

  @override
  Future<RecyTechBin> updateBinStatus({
    required String binId,
    required String status,
    double? fillLevelKg,
    String? notes,
  }) async {
    if (!PartnerBinStatuses.isValid(status)) {
      throw ArgumentError.value(status, 'status', 'Unsupported bin status');
    }
    return fetchBin(binId);
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
