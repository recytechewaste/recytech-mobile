import '../../core/constants/app_constants.dart';
import 'collected_item_model.dart';

class CollectorJob {
  final String id;
  final String residentName;
  final String location;
  final String wasteType;
  final String itemCategory;
  final String detectedClass;
  final int quantity;
  final double ratePerKg;
  final double ratePerItem;
  final String residentEmail;
  final String phone;
  final String wasteImage;
  final String status;
  final String assignedCollector;
  final String assignedCollectorId;
  final String scheduledAt;
  final String createdAt;
  final String updatedAt;
  final String partnerOrganizationName;
  final String binId;
  final String binCode;
  final String binName;
  final double? latitude;
  final double? longitude;
  final double? fillPercentage;
  final String fullnessStatus;
  final String remarks;
  final String requestedAt;
  final String startedAt;
  final String requestType;
  final List<CollectedWastePayloadItem> collectedWaste;
  final DateTime? completionDate;

  const CollectorJob({
    required this.id,
    required this.residentName,
    required this.location,
    required this.wasteType,
    required this.itemCategory,
    required this.detectedClass,
    required this.quantity,
    required this.ratePerKg,
    required this.ratePerItem,
    required this.residentEmail,
    required this.phone,
    required this.wasteImage,
    required this.status,
    required this.assignedCollector,
    required this.assignedCollectorId,
    required this.scheduledAt,
    required this.createdAt,
    required this.updatedAt,
    this.partnerOrganizationName = '',
    this.binId = '',
    this.binCode = '',
    this.binName = '',
    this.latitude,
    this.longitude,
    this.fillPercentage,
    this.fullnessStatus = '',
    this.remarks = '',
    this.requestedAt = '',
    this.startedAt = '',
    this.requestType = '',
    this.collectedWaste = const [],
    this.completionDate,
  });

  String get requestCode => id.isEmpty ? 'Request' : 'CR-$idSuffix';
  String get idSuffix => id.length > 6 ? id.substring(id.length - 6) : id;
  String get schedule => requestedAt.isNotEmpty
      ? requestedAt
      : scheduledAt.isNotEmpty
          ? scheduledAt
          : createdAt;
  String get displayItem {
    if (binName.isNotEmpty && binCode.isNotEmpty) return '$binCode - $binName';
    if (binCode.isNotEmpty) return binCode;
    if (binName.isNotEmpty) return binName;
    return itemCategory.isNotEmpty ? itemCategory : wasteType;
  }

  bool get isQueued =>
      CollectorJobStatuses.normalize(status) == CollectorJobStatuses.assigned;
  bool get isApproved => isQueued;
  bool get isInTransit =>
      CollectorJobStatuses.normalize(status) == CollectorJobStatuses.onTheWay;

  bool get isCompleted {
    return CollectorJobStatuses.normalize(status) ==
        CollectorJobStatuses.completed;
  }

  bool get isRejected {
    return CollectorJobStatuses.normalize(status) ==
        CollectorJobStatuses.cancelled;
  }

  bool get isActive => !isCompleted && !isRejected;
  bool get hasAssignedCollector =>
      _hasMeaningfulValue(assignedCollectorId) ||
      _hasMeaningfulValue(assignedCollector);
  bool get isAvailableForAssignment =>
      id.isNotEmpty && isQueued && isActive && !hasAssignedCollector;

  DateTime? get scheduledDate => DateTime.tryParse(scheduledAt);
  DateTime? get createdDate => DateTime.tryParse(schedule);

  bool isAssignedTo({
    String? collectorId,
    String? collectorName,
    String? collectorEmail,
  }) {
    if (!hasAssignedCollector || !isActive) return false;

    final id = _normalizeMatchValue(collectorId);
    final name = _normalizeMatchValue(collectorName);
    final email = _normalizeMatchValue(collectorEmail);
    final assignedId = _normalizeMatchValue(assignedCollectorId);
    final assignedName = _normalizeMatchValue(assignedCollector);

    if (id.isNotEmpty && assignedId.isNotEmpty && id == assignedId) {
      return true;
    }

    if (name.isNotEmpty && assignedName.isNotEmpty && name == assignedName) {
      return true;
    }

    if (email.isNotEmpty &&
        assignedName.isNotEmpty &&
        assignedName.contains(email)) {
      return true;
    }

    return false;
  }

  factory CollectorJob.fromJson(Map<String, dynamic> json) {
    final locationValue = json['location'];
    final locationMap = _asMap(locationValue);
    final locationAddress = locationMap.isNotEmpty
        ? (locationMap['address'] ?? '').toString()
        : (locationValue ?? json['address'] ?? '').toString();

    final resident = _asMap(json['resident']);
    final assignedCollector = _asMap(json['assignedCollector']);
    final partnerOrganization = _asMap(
      json['lgu'] ?? json['partnerOrganizationId'],
    );
    final bin = _asMap(json['bin']);
    final binLocation = _asMap(bin['location']);
    final canonicalLocation = (binLocation['address'] ??
            bin['address'] ??
            (locationMap.isNotEmpty ? locationMap['address'] : locationValue) ??
            json['address'] ??
            '')
        .toString();
    final assignedCollectorName = [
      assignedCollector['firstName'],
      assignedCollector['lastName'],
    ].where((part) => (part ?? '').toString().trim().isNotEmpty).join(' ');
    final fallbackCollectorName = (json['assignedCollectorName'] ??
            json['collectorName'] ??
            json['collectorFullName'] ??
            json['assignedCollector'] ??
            '')
        .toString();

    return CollectorJob(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      residentName:
          (json['residentName'] ?? json['partnerOrganizationName'] ?? '')
              .toString(),
      location:
          canonicalLocation.isNotEmpty ? canonicalLocation : locationAddress,
      wasteType:
          (json['wasteType'] ?? json['category'] ?? 'Partner Bin').toString(),
      itemCategory: (json['itemCategory'] ??
              json['binName'] ??
              json['binCode'] ??
              json['binId'] ??
              '')
          .toString(),
      detectedClass: (json['detectedClass'] ?? '').toString(),
      quantity: _parseQuantity(json['quantity']),
      ratePerKg: _parseDouble(json['ratePerKg']),
      ratePerItem: _parseDouble(json['ratePerItem']),
      residentEmail:
          (json['residentEmail'] ?? resident['email'] ?? '').toString(),
      phone: (json['phone'] ?? resident['phone'] ?? '').toString(),
      wasteImage: (json['wasteImage'] ?? '').toString(),
      status: RequestStatuses.normalize(
        (json['status'] ?? RequestStatuses.pending).toString(),
      ),
      assignedCollector: assignedCollectorName.isNotEmpty
          ? assignedCollectorName
          : fallbackCollectorName,
      assignedCollectorId: (json['assignedCollectorId'] ??
              assignedCollector['_id'] ??
              assignedCollector['id'] ??
              (json['assignedCollector'] is String
                  ? json['assignedCollector']
                  : ''))
          .toString(),
      scheduledAt:
          (json['scheduledDate'] ?? json['scheduledAt'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? json['requestedAt'] ?? '').toString(),
      updatedAt: (json['updatedAt'] ?? '').toString(),
      partnerOrganizationName: (json['partnerOrganizationName'] ??
              partnerOrganization['name'] ??
              partnerOrganization['organizationName'] ??
              '')
          .toString(),
      binId: (bin['_id'] ?? bin['id'] ?? json['binId'] ?? '').toString(),
      binCode: (bin['binCode'] ??
              bin['code'] ??
              json['binCode'] ??
              json['binId'] ??
              '')
          .toString(),
      binName: (bin['name'] ??
              bin['binName'] ??
              json['binName'] ??
              json['name'] ??
              '')
          .toString(),
      latitude: _parseNullableDouble(
        json['latitude'] ??
            json['lat'] ??
            (binLocation['coordinates'] is List &&
                    (binLocation['coordinates'] as List).length > 1
                ? (binLocation['coordinates'] as List)[1]
                : null),
      ),
      longitude: _parseNullableDouble(
        json['longitude'] ??
            json['lng'] ??
            json['lon'] ??
            (binLocation['coordinates'] is List &&
                    (binLocation['coordinates'] as List).isNotEmpty
                ? (binLocation['coordinates'] as List)[0]
                : null),
      ),
      fillPercentage: _parseNullableDouble(json['fillPercentage']),
      fullnessStatus: (json['fullnessStatus'] ?? '').toString(),
      remarks: (json['remarks'] ?? json['notes'] ?? '').toString(),
      requestedAt: (json['requestedAt'] ?? '').toString(),
      startedAt: (json['startedAt'] ?? '').toString(),
      requestType: (json['requestType'] ?? '').toString(),
      collectedWaste: json['collectedWaste'] is List
          ? (json['collectedWaste'] as List)
              .whereType<Map>()
              .map((item) => CollectedWastePayloadItem.fromJson(
                    item.cast<String, dynamic>(),
                  ))
              .toList(growable: false)
          : const [],
      completionDate: DateTime.tryParse(
        (json['completionDate'] ?? '').toString(),
      ),
    );
  }

  CollectorJob copyWith({
    String? status,
    String? assignedCollector,
    String? assignedCollectorId,
    String? scheduledAt,
    String? updatedAt,
    String? requestedAt,
    String? startedAt,
  }) {
    return CollectorJob(
      id: id,
      residentName: residentName,
      location: location,
      wasteType: wasteType,
      itemCategory: itemCategory,
      detectedClass: detectedClass,
      quantity: quantity,
      ratePerKg: ratePerKg,
      ratePerItem: ratePerItem,
      residentEmail: residentEmail,
      phone: phone,
      wasteImage: wasteImage,
      status: status ?? this.status,
      assignedCollector: assignedCollector ?? this.assignedCollector,
      assignedCollectorId: assignedCollectorId ?? this.assignedCollectorId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      partnerOrganizationName: partnerOrganizationName,
      binId: binId,
      binCode: binCode,
      binName: binName,
      latitude: latitude,
      longitude: longitude,
      fillPercentage: fillPercentage,
      fullnessStatus: fullnessStatus,
      remarks: remarks,
      requestedAt: requestedAt ?? this.requestedAt,
      startedAt: startedAt ?? this.startedAt,
      requestType: requestType,
      collectedWaste: collectedWaste,
      completionDate: completionDate,
    );
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) return value.cast<String, dynamic>();
    return <String, dynamic>{};
  }

  static int _parseQuantity(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? 1;
  }

  static double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '').toString()) ?? 0;
  }

  static double? _parseNullableDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '').toString());
  }

  static bool _hasMeaningfulValue(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized.isNotEmpty &&
        normalized != 'null' &&
        normalized != '{}' &&
        normalized != '[]';
  }

  static String _normalizeMatchValue(String? value) {
    return (value ?? '').trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}
