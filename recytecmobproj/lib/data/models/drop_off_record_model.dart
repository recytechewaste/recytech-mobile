class DropOffRecord {
  const DropOffRecord({
    required this.id,
    required this.binId,
    required this.binName,
    required this.createdAt,
    required this.status,
    this.userId,
    this.building,
    this.locationDescription,
    this.rewardEligible = false,
    this.rewardValue,
    this.rewardPoints,
    this.rewardStatus,
    this.partnerOrganizationName,
    this.submissionMethod,
    this.items = const [],
    this.pointsStatus = 'not_processed',
    this.pointsAwarded = 0,
  });

  final String id;
  final String binId;
  final String binName;
  final String? userId;
  final String? building;
  final String? locationDescription;
  final DateTime createdAt;
  final String status;
  final bool rewardEligible;
  final String? rewardValue;
  final int? rewardPoints;
  final String? rewardStatus;
  final String? partnerOrganizationName;
  final String? submissionMethod;
  final List<DropOffRecordItem> items;
  final String pointsStatus;
  final int pointsAwarded;

  String get locationLabel {
    final parts = [
      building,
      locationDescription,
    ].where((part) => (part ?? '').trim().isNotEmpty).cast<String>();
    return parts.isEmpty ? '-' : parts.join(' - ');
  }

  String get rewardLabel {
    if (pointsAwarded > 0) {
      return '+$pointsAwarded point${pointsAwarded == 1 ? '' : 's'}';
    }
    if (!rewardEligible) return 'Not eligible';
    final value = (rewardValue ?? '').trim();
    if (value.isNotEmpty) return value;
    final points = rewardPoints;
    if (points != null && points > 0) {
      return '$points point${points == 1 ? '' : 's'}';
    }
    return 'Eligible';
  }

  factory DropOffRecord.fromJson(Map<String, dynamic> json) {
    final bin = _asMap(json['bin']);
    final created = DateTime.tryParse(
          (json['createdAt'] ?? json['timestamp'] ?? '').toString(),
        ) ??
        DateTime.fromMillisecondsSinceEpoch(0);

    return DropOffRecord(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      binId: (json['binId'] ?? json['binCode'] ?? bin['id'] ?? bin['_id'] ?? '')
          .toString(),
      binName: (json['binName'] ?? bin['name'] ?? 'RecyTech Bin').toString(),
      userId: _optionalString(json['userId']),
      building: _optionalString(json['building'] ?? bin['building']),
      locationDescription: _optionalString(
        json['locationDescription'] ??
            json['location'] ??
            bin['locationDescription'] ??
            bin['address'],
      ),
      createdAt: created,
      status: (json['status'] ?? 'Recorded').toString(),
      rewardEligible: json['rewardEligible'] == true,
      rewardValue: _optionalString(json['rewardValue'] ?? json['reward']),
      rewardPoints: _parseInt(json['rewardPoints'] ?? json['points']),
      rewardStatus: _optionalString(json['rewardStatus']),
      partnerOrganizationName: _optionalString(
        json['partnerOrganizationName'] ?? json['partnerName'],
      ),
      submissionMethod: _optionalString(json['submissionMethod']),
      items: _readItems(json['items']),
      pointsStatus: (json['pointsStatus'] ?? 'not_processed').toString(),
      pointsAwarded: _parseInt(json['pointsAwarded']) ??
          _parseInt(json['rewardPoints'] ?? json['points']) ??
          0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'binId': binId,
        'binName': binName,
        if (userId != null) 'userId': userId,
        if (building != null) 'building': building,
        if (locationDescription != null)
          'locationDescription': locationDescription,
        'createdAt': createdAt.toIso8601String(),
        'status': status,
        'rewardEligible': rewardEligible,
        if (rewardValue != null) 'rewardValue': rewardValue,
        if (rewardPoints != null) 'rewardPoints': rewardPoints,
        if (rewardStatus != null) 'rewardStatus': rewardStatus,
        if (partnerOrganizationName != null)
          'partnerOrganizationName': partnerOrganizationName,
        if (submissionMethod != null) 'submissionMethod': submissionMethod,
        'items': items.map((item) => item.toJson()).toList(),
        'pointsStatus': pointsStatus,
        'pointsAwarded': pointsAwarded,
      };

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) return value.cast<String, dynamic>();
    return <String, dynamic>{};
  }

  static String? _optionalString(dynamic value) {
    final text = (value ?? '').toString().trim();
    return text.isEmpty ? null : text;
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString());
  }

  static List<DropOffRecordItem> _readItems(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => DropOffRecordItem.fromJson(item.cast<String, dynamic>()))
        .toList(growable: false);
  }
}

class DropOffRecordItem {
  const DropOffRecordItem({
    required this.category,
    required this.quantity,
    this.categoryLabel,
  });

  final String category;
  final int quantity;
  final String? categoryLabel;

  factory DropOffRecordItem.fromJson(Map<String, dynamic> json) {
    final category = (json['category'] ?? '').toString();
    return DropOffRecordItem(
      category: category,
      categoryLabel:
          _optionalString(json['categoryLabel']) ?? _displayCategory(category),
      quantity: _parseInt(json['quantity']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'category': category,
        'quantity': quantity,
        if (categoryLabel != null) 'categoryLabel': categoryLabel,
      };

  static String? _optionalString(dynamic value) {
    final text = (value ?? '').toString().trim();
    return text.isEmpty ? null : text;
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString());
  }

  static String _displayCategory(String value) {
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
}
