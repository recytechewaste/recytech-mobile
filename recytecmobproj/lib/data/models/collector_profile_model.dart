class CollectorProfile {
  const CollectorProfile({
    required this.profileId,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.vehiclePlate,
    required this.vehicleType,
    required this.status,
    required this.activeJobs,
    required this.completedJobs,
  });

  final String profileId;
  final String userId;
  final String firstName;
  final String lastName;
  final String email;
  final String vehiclePlate;
  final String vehicleType;
  final String status;
  final int activeJobs;
  final int completedJobs;

  String get fullName => [firstName, lastName]
      .where((part) => part.trim().isNotEmpty)
      .join(' ')
      .trim();
  bool get isActive => status == 'Active';

  factory CollectorProfile.fromJson(Map<String, dynamic> json) {
    final profile = _map(json['profile']);
    final user = _map(json['user']);
    final stats = _map(json['stats']);
    final status = (profile['status'] ?? user['status'] ?? 'Active').toString();
    final name = _personIdentity(profile, user);

    return CollectorProfile(
      profileId: (profile['_id'] ?? profile['id'] ?? '').toString(),
      userId: (user['_id'] ?? user['id'] ?? '').toString(),
      firstName: name.first,
      lastName: name.last,
      email: (user['email'] ?? '').toString(),
      vehiclePlate:
          (profile['vehiclePlate'] ?? profile['plateNumber'] ?? '').toString(),
      vehicleType: (profile['vehicleType'] ?? '').toString(),
      status: status == 'Inactive' ? 'Inactive' : 'Active',
      activeJobs: _integer(stats['activeJobs']),
      completedJobs: _integer(stats['completedJobs']),
    );
  }

  CollectorProfile copyWith({String? status}) => CollectorProfile(
        profileId: profileId,
        userId: userId,
        firstName: firstName,
        lastName: lastName,
        email: email,
        vehiclePlate: vehiclePlate,
        vehicleType: vehicleType,
        status: status ?? this.status,
        activeJobs: activeJobs,
        completedJobs: completedJobs,
      );

  static Map<String, dynamic> _map(dynamic value) =>
      value is Map ? value.cast<String, dynamic>() : <String, dynamic>{};

  static ({String first, String last}) _personIdentity(
    Map<String, dynamic> profile,
    Map<String, dynamic> user,
  ) {
    final candidates = [profile, user];
    for (final requireBoth in const [true, false]) {
      for (final fields in candidates) {
        final first = (fields['firstName'] ?? '').toString().trim();
        final last = (fields['lastName'] ?? '').toString().trim();
        if (requireBoth && (first.isEmpty || last.isEmpty)) continue;
        final fullName =
            [first, last].where((part) => part.isNotEmpty).join(' ').trim();
        final normalized =
            fullName.toLowerCase().replaceAll(RegExp(r'[_\s]+'), ' ');
        if (fullName.isNotEmpty &&
            !const {'collector', 'user collector'}.contains(normalized)) {
          return (first: first, last: last);
        }
      }
    }
    return (first: '', last: '');
  }

  static int _integer(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? 0;
  }
}

class CollectorStats {
  const CollectorStats(this.values);

  final Map<String, dynamic> values;

  factory CollectorStats.fromJson(Map<String, dynamic> json) {
    final source = json['stats'] is Map
        ? (json['stats'] as Map).cast<String, dynamic>()
        : json;
    return CollectorStats(Map<String, dynamic>.unmodifiable(source));
  }
}
