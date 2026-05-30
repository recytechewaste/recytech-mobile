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
  });

  String get requestCode => id.isEmpty ? 'Request' : 'REQ-$idSuffix';
  String get idSuffix => id.length > 6 ? id.substring(id.length - 6) : id;
  String get schedule => scheduledAt.isNotEmpty ? scheduledAt : createdAt;
  String get displayItem => itemCategory.isNotEmpty ? itemCategory : wasteType;
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isInTransit => status.toLowerCase() == 'in-transit';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isRejected => status.toLowerCase() == 'rejected';

  factory CollectorJob.fromJson(Map<String, dynamic> json) {
    final locationValue = json['location'];
    final locationMap = _asMap(locationValue);
    final locationAddress = locationMap.isNotEmpty
        ? (locationMap['address'] ?? '').toString()
        : (locationValue ?? json['address'] ?? '').toString();

    final resident = _asMap(json['resident']);
    final assignedCollector = _asMap(json['assignedCollector']);
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
      residentName: (json['residentName'] ?? '').toString(),
      location: locationAddress,
      wasteType: (json['wasteType'] ?? json['category'] ?? '').toString(),
      itemCategory: (json['itemCategory'] ?? '').toString(),
      detectedClass: (json['detectedClass'] ?? '').toString(),
      quantity: _parseQuantity(json['quantity']),
      ratePerKg: _parseDouble(json['ratePerKg']),
      ratePerItem: _parseDouble(json['ratePerItem']),
      residentEmail:
          (json['residentEmail'] ?? resident['email'] ?? '').toString(),
      phone: (json['phone'] ?? resident['phone'] ?? '').toString(),
      wasteImage: (json['wasteImage'] ?? '').toString(),
      status: (json['status'] ?? 'Pending').toString(),
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
      scheduledAt: (json['scheduledAt'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
      updatedAt: (json['updatedAt'] ?? '').toString(),
    );
  }

  CollectorJob copyWith({
    String? status,
    String? assignedCollector,
    String? assignedCollectorId,
    String? scheduledAt,
    String? updatedAt,
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
}
