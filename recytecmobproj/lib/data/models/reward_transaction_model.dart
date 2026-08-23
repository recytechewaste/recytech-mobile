class RewardTransaction {
  const RewardTransaction({
    required this.id,
    required this.dropOffId,
    required this.createdAt,
    required this.status,
    this.rewardValue,
    this.rewardPoints,
    this.binName,
    this.locationDescription,
  });

  final String id;
  final String dropOffId;
  final DateTime createdAt;
  final String status;
  final String? rewardValue;
  final int? rewardPoints;
  final String? binName;
  final String? locationDescription;

  String get rewardLabel {
    final value = (rewardValue ?? '').trim();
    if (value.isNotEmpty) return value;
    final points = rewardPoints;
    if (points != null && points > 0) {
      return '$points point${points == 1 ? '' : 's'}';
    }
    return 'No reward';
  }

  factory RewardTransaction.fromJson(Map<String, dynamic> json) {
    final created = DateTime.tryParse(
          (json['createdAt'] ?? json['timestamp'] ?? '').toString(),
        ) ??
        DateTime.fromMillisecondsSinceEpoch(0);

    return RewardTransaction(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      dropOffId: (json['dropOffId'] ?? json['dropoffId'] ?? '').toString(),
      createdAt: created,
      status: (json['status'] ?? 'Recorded').toString(),
      rewardValue: _optionalString(json['rewardValue'] ?? json['reward']),
      rewardPoints: _parseInt(json['rewardPoints'] ?? json['points']),
      binName: _optionalString(json['binName']),
      locationDescription: _optionalString(json['locationDescription']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'dropOffId': dropOffId,
        'createdAt': createdAt.toIso8601String(),
        'status': status,
        if (rewardValue != null) 'rewardValue': rewardValue,
        if (rewardPoints != null) 'rewardPoints': rewardPoints,
        if (binName != null) 'binName': binName,
        if (locationDescription != null)
          'locationDescription': locationDescription,
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
}
