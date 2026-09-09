class DropOffStatuses {
  const DropOffStatuses._();

  static const pending = 'pending';
  static const approved = 'approved';
  static const rejected = 'rejected';
  static const values = [pending, approved, rejected];

  static String normalize(String? value) {
    final normalized =
        (value ?? '').trim().toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_');
    if (values.contains(normalized)) return normalized;

    switch (normalized) {
      case 'submitted':
      case 'recorded':
        return pending;
      case 'accepted':
      case 'verified':
        return approved;
      case 'declined':
        return rejected;
      default:
        throw FormatException('Unsupported drop-off status: $value');
    }
  }

  static String label(String? value) {
    switch (normalize(value)) {
      case pending:
        return 'Pending';
      case approved:
        return 'Approved';
      case rejected:
        return 'Rejected';
    }
    throw StateError('Unreachable drop-off status label');
  }
}

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
    this.pointsProjected,
    this.imageUrls = const [],
    this.rejectionNotes,
    this.transactionId,
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
  final int? pointsProjected;
  final List<String> imageUrls;
  final String? rejectionNotes;
  final String? transactionId;

  String get statusLabel => DropOffStatuses.label(status);

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
    final transaction = _asMap(json['transaction']);
    final created = DateTime.tryParse(
          (json['createdAt'] ?? json['timestamp'] ?? '').toString(),
        ) ??
        DateTime.fromMillisecondsSinceEpoch(0);

    return DropOffRecord(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      binId: (json['binId'] ??
              json['binCode'] ??
              bin['id'] ??
              bin['_id'] ??
              (json['bin'] is String ? json['bin'] : ''))
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
      status: DropOffStatuses.normalize(json['status']?.toString()),
      rewardEligible: json['rewardEligible'] == true,
      rewardValue: _optionalString(json['rewardValue'] ?? json['reward']),
      rewardPoints: _parseInt(json['rewardPoints'] ?? json['points']),
      rewardStatus: _optionalString(json['rewardStatus']),
      partnerOrganizationName: _optionalString(
        json['partnerOrganizationName'] ?? json['partnerName'],
      ),
      submissionMethod: _optionalString(json['submissionMethod']),
      items: _readItems(
        json['items'],
        category: json['category'] ?? json['wasteType'],
        quantity: json['quantity'],
      ),
      pointsStatus: (json['pointsStatus'] ?? 'not_processed').toString(),
      pointsAwarded: _parseInt(json['pointsAwarded']) ??
          _parseInt(json['rewardPoints'] ?? json['points']) ??
          0,
      pointsProjected:
          _parseInt(json['projectedPoints'] ?? json['pointsProjected']),
      imageUrls: _readImageUrls(
        json['image'] ??
            json['images'] ??
            json['photos'] ??
            json['eWasteImages'],
      ),
      rejectionNotes: _optionalString(
        json['rejectionNotes'] ?? json['rejectionReason'],
      ),
      transactionId: _optionalString(
        transaction['_id'] ??
            transaction['id'] ??
            json['transactionId'] ??
            (json['transaction'] is String ? json['transaction'] : null),
      ),
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
        if (pointsProjected != null) 'pointsProjected': pointsProjected,
        'imageUrls': imageUrls,
        if (rejectionNotes != null) 'rejectionNotes': rejectionNotes,
        if (transactionId != null) 'transactionId': transactionId,
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

  static List<DropOffRecordItem> _readItems(
    dynamic value, {
    dynamic category,
    dynamic quantity,
  }) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map(
            (item) => DropOffRecordItem.fromJson(
              item.cast<String, dynamic>(),
            ),
          )
          .toList(growable: false);
    }

    final categoryText = (category ?? '').toString().trim();
    final parsedQuantity = _parseNum(quantity);
    if (categoryText.isEmpty || parsedQuantity == null) return const [];
    return [
      DropOffRecordItem(category: categoryText, quantity: parsedQuantity),
    ];
  }

  static num? _parseNum(dynamic value) {
    if (value is num) return value;
    return num.tryParse((value ?? '').toString());
  }

  static List<String> _readImageUrls(dynamic value) {
    if (value is String && value.trim().isNotEmpty) return [value.trim()];
    if (value is! List) return const [];
    return value
        .map((item) {
          if (item is Map) {
            return (item['url'] ?? item['imageUrl'] ?? '').toString().trim();
          }
          return item.toString().trim();
        })
        .where((item) => item.isNotEmpty)
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
  final num quantity;
  final String? categoryLabel;

  factory DropOffRecordItem.fromJson(Map<String, dynamic> json) {
    final category = (json['category'] ?? '').toString();
    return DropOffRecordItem(
      category: category,
      categoryLabel:
          _optionalString(json['categoryLabel']) ?? _displayCategory(category),
      quantity: _parseNum(json['quantity']) ?? 0,
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

  static num? _parseNum(dynamic value) {
    if (value is num) return value;
    return num.tryParse((value ?? '').toString());
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
