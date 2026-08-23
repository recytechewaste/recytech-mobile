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

  String get locationLabel {
    final parts = [
      building,
      locationDescription,
    ].where((part) => (part ?? '').trim().isNotEmpty).cast<String>();
    return parts.isEmpty ? '-' : parts.join(' - ');
  }

  String get rewardLabel {
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
      binId: (json['binId'] ?? bin['id'] ?? bin['_id'] ?? '').toString(),
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
}
