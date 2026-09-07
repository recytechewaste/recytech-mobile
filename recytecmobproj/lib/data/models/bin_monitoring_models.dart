import '../../core/constants/app_constants.dart';

class RecyTechBin {
  const RecyTechBin({
    String? binId,
    String? id,
    String? binName,
    String? name,
    this.assignedLguId,
    this.partnerOrganizationName,
    this.publicQrCode,
    this.acceptedCategories = const [],
    this.acceptedCategoryLabels = const [],
    required this.location,
    this.distanceCm,
    double? fillPercentage,
    double? fillLevel,
    String? fullnessStatus,
    String? sensorStatus,
    this.controllerStatus,
    this.latitude,
    this.longitude,
    DateTime? lastUpdatedAt,
    DateTime? lastMonitoringUpdate,
    DateTime? lastCollectionAt,
    DateTime? lastCollectionDate,
    this.activeCollectionRequest,
    this.isActive = true,
    this.cameraStatus = 'Legacy camera disabled',
    this.latestImageUrl,
  })  : binId = binId ?? id ?? '',
        binName = binName ?? name,
        fillPercentage = fillPercentage ?? fillLevel,
        fullnessStatus = fullnessStatus ?? FullnessStatuses.requiresInspection,
        sensorStatus = sensorStatus ?? SensorStatuses.unknown,
        lastUpdatedAt = lastUpdatedAt ?? lastMonitoringUpdate,
        lastCollectionAt = lastCollectionAt ?? lastCollectionDate;

  final String binId;
  final String? binName;
  final String? assignedLguId;
  final String? partnerOrganizationName;
  final String? publicQrCode;
  final List<String> acceptedCategories;
  final List<String> acceptedCategoryLabels;
  final String location;
  final double? distanceCm;
  final double? fillPercentage;
  final String fullnessStatus;
  final String sensorStatus;
  final String? controllerStatus;
  final double? latitude;
  final double? longitude;
  final DateTime? lastUpdatedAt;
  final DateTime? lastCollectionAt;
  final CollectionRequestSummary? activeCollectionRequest;
  final bool isActive;

  // Legacy fields kept only so old unrouted camera/deposit screens still compile.
  final String cameraStatus;
  final String? latestImageUrl;

  String get id => binId;
  String? get name => binName;
  double? get fillLevel => fillPercentage;
  DateTime? get lastMonitoringUpdate => lastUpdatedAt;
  DateTime? get lastCollectionDate => lastCollectionAt;

  String get displayName {
    final value = binName?.trim() ?? '';
    return value.isEmpty ? binId : value;
  }

  bool get hasActiveCollectionRequest =>
      activeCollectionRequest != null &&
      CollectionRequestStatuses.isActive(activeCollectionRequest!.status);

  factory RecyTechBin.fromJson(Map<String, dynamic> json) {
    return RecyTechBin(
      binId: _readString(json, ['binId', 'binCode', 'code', 'id', '_id']),
      binName:
          _nullableString(json['binName'] ?? json['name'] ?? json['label']),
      assignedLguId: _nullableString(
        json['assignedLguId'] ??
            json['lguId'] ??
            json['assigned_lgu_id'] ??
            json['partnerOrganizationId'],
      ),
      partnerOrganizationName: _nullableString(
        json['partnerOrganizationName'] ??
            json['partnerName'] ??
            json['organizationName'],
      ),
      publicQrCode: _nullableString(json['publicQrCode']),
      acceptedCategories: _readStringList(json['acceptedCategories']),
      acceptedCategoryLabels: _readCategoryLabels(
        json['acceptedCategoryDisplayNames'],
        json['acceptedCategories'],
      ),
      location: _readString(json, ['location', 'address']),
      distanceCm: _readDouble(json['distanceCm'] ?? json['distance_cm']),
      fillPercentage: _readDouble(
        json['fillPercentage'] ??
            json['fill_percentage'] ??
            json['fillLevel'] ??
            json['fillLevelPercentage'] ??
            json['latestFillPercentage'],
      ),
      fullnessStatus: FullnessStatuses.normalize(
        _readString(
          json,
          ['fullnessStatus', 'status', 'currentFullnessStatus'],
          fallback: FullnessStatuses.requiresInspection,
        ),
      ),
      sensorStatus: SensorStatuses.normalize(
        _readString(
          json,
          ['sensorStatus', 'sensorConnectionStatus', 'latestSensorStatus'],
          fallback: SensorStatuses.unknown,
        ),
      ),
      controllerStatus: _nullableString(
        json['controllerStatus'] ?? json['esp32Status'],
      ),
      latitude: _readDouble(json['latitude'] ?? json['lat']),
      longitude: _readDouble(json['longitude'] ?? json['lng'] ?? json['lon']),
      lastUpdatedAt: _readDate(
        json['lastUpdatedAt'] ??
            json['lastMonitoringUpdate'] ??
            json['lastSensorUpdatedAt'],
      ),
      lastCollectionAt: _readDate(
        json['lastCollectionAt'] ?? json['lastCollectionDate'],
      ),
      activeCollectionRequest: _readMap(json['activeCollectionRequest']).isEmpty
          ? null
          : CollectionRequestSummary.fromJson(
              _readMap(json['activeCollectionRequest']),
            ),
      isActive: !_hasKey(json, 'isActive') || _readBool(json['isActive']),
      cameraStatus: _readString(
        json,
        ['cameraStatus', 'cameraConnectionStatus'],
        fallback: 'Legacy camera disabled',
      ),
      latestImageUrl: _nullableString(json['latestImageUrl']),
    );
  }
}

class BinMonitoringData {
  const BinMonitoringData({
    required this.binId,
    this.distanceCm,
    double? fillPercentage,
    double? fillLevel,
    String? fullnessStatus,
    String? sensorStatus,
    this.controllerStatus,
    this.lastUpdatedAt,
    this.activeCollectionRequest,
    this.latestImageUrl,
    this.cameraStatus = 'Legacy camera disabled',
  })  : fillPercentage = fillPercentage ?? fillLevel,
        fullnessStatus = fullnessStatus ?? FullnessStatuses.requiresInspection,
        sensorStatus = sensorStatus ?? SensorStatuses.unknown;

  final String binId;
  final double? distanceCm;
  final double? fillPercentage;
  final String fullnessStatus;
  final String sensorStatus;
  final String? controllerStatus;
  final DateTime? lastUpdatedAt;
  final CollectionRequestSummary? activeCollectionRequest;

  // Legacy fields kept only so old unrouted camera/deposit screens still compile.
  final String? latestImageUrl;
  final String cameraStatus;

  double? get fillLevel => fillPercentage;

  factory BinMonitoringData.fromJson(Map<String, dynamic> json) {
    return BinMonitoringData(
      binId: _readString(json, ['binId']),
      distanceCm: _readDouble(json['distanceCm'] ?? json['distance_cm']),
      fillPercentage: _readDouble(
        json['fillPercentage'] ?? json['fillLevel'],
      ),
      fullnessStatus: FullnessStatuses.normalize(
        _readString(
          json,
          ['fullnessStatus'],
          fallback: FullnessStatuses.requiresInspection,
        ),
      ),
      sensorStatus: SensorStatuses.normalize(
        _readString(
          json,
          ['sensorStatus'],
          fallback: SensorStatuses.unknown,
        ),
      ),
      controllerStatus: _nullableString(json['controllerStatus']),
      lastUpdatedAt: _readDate(
        json['lastUpdatedAt'] ?? json['lastSensorUpdatedAt'],
      ),
      activeCollectionRequest: _readMap(json['activeCollectionRequest']).isEmpty
          ? null
          : CollectionRequestSummary.fromJson(
              _readMap(json['activeCollectionRequest']),
            ),
      latestImageUrl: _nullableString(json['latestImageUrl']),
      cameraStatus: _readString(
        json,
        ['cameraStatus'],
        fallback: 'Legacy camera disabled',
      ),
    );
  }
}

class SensorReadingFreshness {
  const SensorReadingFreshness._();

  static const staleAfter = Duration(hours: 2);

  static String status(DateTime? lastUpdatedAt, {DateTime? now}) {
    if (lastUpdatedAt == null) return 'Unknown';
    final reference = now ?? DateTime.now();
    if (lastUpdatedAt.isAfter(reference)) return 'Unknown';
    return reference.difference(lastUpdatedAt) > staleAfter
        ? 'Stale'
        : 'Current';
  }

  static bool isStale(DateTime? lastUpdatedAt, {DateTime? now}) {
    return status(lastUpdatedAt, now: now) == 'Stale';
  }
}

class CollectionRequestSummary {
  const CollectionRequestSummary({
    required this.id,
    required this.binId,
    required this.location,
    required this.status,
    required this.requestedAt,
    this.lguId,
    this.partnerOrganizationName,
    this.binName,
    this.latitude,
    this.longitude,
    this.fillPercentage,
    this.fullnessStatus,
    this.reason = '',
    this.remarks,
    this.assignedCollectorName,
    this.startedAt,
    this.completedAt,
    this.completionItemSummaryText,
    this.completionTotalQuantity,
    this.completionTotalWeightKg,
  });

  final String id;
  final String? lguId;
  final String? partnerOrganizationName;
  final String binId;
  final String? binName;
  final String location;
  final double? latitude;
  final double? longitude;
  final double? fillPercentage;
  final String? fullnessStatus;
  final String status;
  final DateTime requestedAt;
  final String reason;
  final String? remarks;
  final String? assignedCollectorName;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? completionItemSummaryText;
  final int? completionTotalQuantity;
  final double? completionTotalWeightKg;

  factory CollectionRequestSummary.fromJson(Map<String, dynamic> json) {
    final completionReport = _readMap(json['completionReport']);
    final itemSummary = completionReport['itemSummary'];
    final optionalWeight = _readMap(completionReport['optionalTotalWeight']);

    return CollectionRequestSummary(
      id: _readString(json, ['id', '_id', 'reference', 'requestCode']),
      lguId: _nullableString(
        json['lguId'] ?? json['lgu_id'] ?? json['partnerOrganizationId'],
      ),
      partnerOrganizationName: _nullableString(
        json['partnerOrganizationName'] ?? json['organizationName'],
      ),
      binId: _readString(json, ['binId', 'binCode']),
      binName: _nullableString(json['binName'] ?? json['name']),
      location: _readString(json, ['location', 'binLocation', 'address']),
      latitude: _readDouble(json['latitude'] ?? json['lat']),
      longitude: _readDouble(json['longitude'] ?? json['lng'] ?? json['lon']),
      fillPercentage: _readDouble(
        json['fillPercentage'] ??
            json['currentFillPercentage'] ??
            json['latestFillPercentage'],
      ),
      fullnessStatus: _nullableString(
        json['fullnessStatus'] ?? json['currentFullnessStatus'],
      ),
      status: CollectionRequestStatuses.normalize(
        _readString(json, ['status'],
            fallback: CollectionRequestStatuses.pending),
      ),
      requestedAt: _readDate(
            json['requestedAt'] ??
                json['requestTimestamp'] ??
                json['createdAt'],
          ) ??
          DateTime.now(),
      reason: _readString(json, ['reason'], fallback: ''),
      remarks: _nullableString(json['remarks'] ?? json['notes']),
      assignedCollectorName: _nullableString(
        json['assignedCollectorName'] ?? json['collectorName'],
      ),
      startedAt: _readDate(json['startedAt']),
      completedAt: _readDate(json['completedAt']),
      completionItemSummaryText: _itemSummaryText(itemSummary),
      completionTotalQuantity: _readInt(completionReport['totalQuantity']),
      completionTotalWeightKg: _readDouble(optionalWeight['totalWeightKg']),
    );
  }
}

// Legacy camera/deposit architecture retained for comparison during migration.
// It is intentionally detached from the active routed LGU ToF monitoring UI.
class DepositEvent {
  const DepositEvent({
    required this.id,
    required this.binId,
    required this.cameraId,
    required this.imageUrl,
    required this.capturedAt,
    required this.detections,
    required this.status,
    required this.requiresVerification,
    required this.createdAt,
    required this.updatedAt,
    this.errorStatus,
    this.verificationStatus = 'Pending',
  });

  final String id;
  final String binId;
  final String cameraId;
  final String imageUrl;
  final DateTime capturedAt;
  final List<ObjectDetection> detections;
  final String status;
  final bool requiresVerification;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? errorStatus;
  final String verificationStatus;

  factory DepositEvent.fromJson(Map<String, dynamic> json) {
    final detections = json['detections'];
    final parsedDetections = detections is List
        ? detections
            .whereType<Map>()
            .map((item) =>
                ObjectDetection.fromJson(item.cast<String, dynamic>()))
            .toList()
        : <ObjectDetection>[];
    final now = DateTime.now();

    return DepositEvent(
      id: _readString(json, ['id', '_id', 'depositEventId']),
      binId: _readString(json, ['binId']),
      cameraId: _readString(json, ['cameraId']),
      imageUrl: _readString(json, ['imageUrl', 'capturedImageUrl']),
      capturedAt: _readDate(json['capturedAt']) ?? now,
      detections: parsedDetections,
      status:
          _readString(json, ['status', 'detectionStatus'], fallback: 'Saved'),
      requiresVerification: _readBool(json['requiresVerification']),
      createdAt: _readDate(json['createdAt']) ?? now,
      updatedAt: _readDate(json['updatedAt']) ?? now,
      errorStatus: _nullableString(json['errorStatus'] ?? json['error']),
      verificationStatus: _readString(
        json,
        ['verificationStatus'],
        fallback: _readBool(json['requiresVerification'])
            ? 'Needs verification'
            : 'Not required',
      ),
    );
  }

  ObjectDetection? get bestDetection {
    if (detections.isEmpty) return null;
    final sorted = List<ObjectDetection>.from(detections)
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
    return sorted.first;
  }

  bool get isLowConfidence =>
      requiresVerification ||
      detections.any((detection) => detection.confidence < 0.70) ||
      (errorStatus ?? '').toLowerCase().contains('confidence');
}

class ObjectDetection {
  const ObjectDetection({
    required this.objectClass,
    required this.confidence,
    required this.mappedCategory,
    required this.boundingBox,
    required this.modelVersion,
    this.isVerified = false,
    this.verifiedClass,
    this.verifiedBy,
    this.verifiedAt,
  });

  final String objectClass;
  final double confidence;
  final String mappedCategory;
  final BoundingBox boundingBox;
  final String modelVersion;
  final bool isVerified;
  final String? verifiedClass;
  final String? verifiedBy;
  final DateTime? verifiedAt;

  factory ObjectDetection.fromJson(Map<String, dynamic> json) {
    return ObjectDetection(
      objectClass: _readString(json, ['objectClass', 'class', 'label']),
      confidence: _readDouble(json['confidence']) ?? 0,
      mappedCategory: _readString(
        json,
        ['mappedCategory', 'category'],
        fallback: 'Unmapped e-waste',
      ),
      boundingBox: BoundingBox.fromJson(_readMap(json['boundingBox'])),
      modelVersion: _readString(
        json,
        ['modelVersion'],
        fallback: 'recytech_yolov8_v1',
      ),
      isVerified: _readBool(json['isVerified']),
      verifiedClass: _nullableString(json['verifiedClass']),
      verifiedBy: _nullableString(json['verifiedBy']),
      verifiedAt: _readDate(json['verifiedAt']),
    );
  }
}

class BoundingBox {
  const BoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final double x;
  final double y;
  final double width;
  final double height;

  factory BoundingBox.fromJson(Map<String, dynamic> json) {
    return BoundingBox(
      x: _readDouble(json['x']) ?? 0,
      y: _readDouble(json['y']) ?? 0,
      width: _readDouble(json['width']) ?? 0,
      height: _readDouble(json['height']) ?? 0,
    );
  }
}

class CollectionReport {
  const CollectionReport({
    required this.assignmentId,
    required this.depositEventIds,
    required this.detectedCategories,
    required this.confirmedCategories,
    required this.actualQuantity,
    required this.completionStatus,
    this.beforeImage,
    this.afterImage,
    this.collectorRemarks,
    this.discrepancies,
  });

  final String assignmentId;
  final List<String> depositEventIds;
  final List<String> detectedCategories;
  final List<String> confirmedCategories;
  final int actualQuantity;
  final String? beforeImage;
  final String? afterImage;
  final String? collectorRemarks;
  final String? discrepancies;
  final String completionStatus;

  Map<String, dynamic> toJson() {
    return {
      'assignmentId': assignmentId,
      'depositEventIds': depositEventIds,
      'detectedCategories': detectedCategories,
      'confirmedCategories': confirmedCategories,
      'actualQuantity': actualQuantity,
      'beforeImage': beforeImage,
      'afterImage': afterImage,
      'collectorRemarks': collectorRemarks,
      'discrepancies': discrepancies,
      'completionStatus': completionStatus,
    };
  }
}

String _readString(
  Map<String, dynamic> json,
  List<String> keys, {
  String fallback = '',
}) {
  for (final key in keys) {
    final value = json[key];
    final text = (value ?? '').toString().trim();
    if (text.isNotEmpty && text != 'null') return text;
  }
  return fallback;
}

String? _nullableString(dynamic value) {
  final text = (value ?? '').toString().trim();
  return text.isEmpty || text == 'null' ? null : text;
}

List<String> _readStringList(dynamic value) {
  if (value is! List) return const [];
  return value
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

List<String> _readCategoryLabels(dynamic labels, dynamic fallback) {
  if (labels is List) {
    final parsed = labels
        .map((item) {
          if (item is Map) {
            return (item['label'] ?? item['value'] ?? '').toString().trim();
          }
          return item.toString().trim();
        })
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    if (parsed.isNotEmpty) return parsed;
  }

  return _readStringList(fallback).map(_displayCategory).toList();
}

String _displayCategory(String value) {
  final normalized = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[\s-]+'), '_')
      .replaceAll(RegExp(r'_+'), '_');
  if (normalized == 'pcb') return 'PCB';
  return normalized
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1))
      .join(' ');
}

Map<String, dynamic> _readMap(dynamic value) {
  if (value is Map) return value.cast<String, dynamic>();
  return <String, dynamic>{};
}

double? _readDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse((value ?? '').toString());
}

bool _readBool(dynamic value) {
  if (value is bool) return value;
  final text = (value ?? '').toString().toLowerCase();
  return text == 'true' || text == '1' || text == 'yes';
}

bool _hasKey(Map<String, dynamic> json, String key) {
  return json.containsKey(key);
}

int? _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse((value ?? '').toString());
}

DateTime? _readDate(dynamic value) {
  final text = (value ?? '').toString().trim();
  if (text.isEmpty) return null;
  return DateTime.tryParse(text);
}

String? _itemSummaryText(dynamic value) {
  if (value is! List || value.isEmpty) return null;
  final parts = value
      .whereType<Map>()
      .map((entry) {
        final map = entry.cast<String, dynamic>();
        final category = _nullableString(map['category']);
        final quantity = _readInt(map['quantity']);
        if (category == null || quantity == null) return '';
        return '$category x $quantity';
      })
      .where((part) => part.isNotEmpty)
      .toList();
  return parts.isEmpty ? null : parts.join(', ');
}
