import '../../core/constants/app_constants.dart';

class UnifiedProfile {
  const UnifiedProfile({
    required this.userId,
    required this.profileId,
    required this.email,
    required this.role,
    required this.status,
    required this.accountStatus,
    required this.userFields,
    required this.linkedProfileFields,
    this.pointsBalance,
  });

  final String userId;
  final String profileId;
  final String email;
  final String role;
  final String status;
  final String accountStatus;
  final Map<String, dynamic> userFields;
  final Map<String, dynamic> linkedProfileFields;
  final int? pointsBalance;

  String get roleLabel => AppRoles.displayName(AppRoles.normalize(role));

  /// The backend-owned person or organization name for the active role.
  ///
  /// Role labels are deliberately rejected here so they cannot become profile
  /// identity when a backend name is missing.
  String? get identityName => switch (role) {
        AppRoles.partnerOrg => _firstIdentityValue([
            linkedProfileFields['organizationName'],
            linkedProfileFields['name'],
            linkedProfileFields['displayName'],
            userFields['organizationName'],
            userFields['accountName'],
            userFields['name'],
            userFields['displayName'],
          ]),
        AppRoles.collector => _firstIdentityValue([
            _personName(linkedProfileFields),
            linkedProfileFields['fullName'],
            linkedProfileFields['name'],
            linkedProfileFields['displayName'],
            _personName(userFields),
            userFields['fullName'],
            userFields['displayName'],
            userFields['name'],
          ]),
        AppRoles.household => _firstIdentityValue([
            _personName(userFields),
            userFields['fullName'],
            userFields['displayName'],
            userFields['name'],
            _personName(linkedProfileFields),
            linkedProfileFields['fullName'],
            linkedProfileFields['displayName'],
            linkedProfileFields['name'],
          ]),
        _ => null,
      };

  factory UnifiedProfile.fromJson(Map<String, dynamic> json) {
    final root = _map(json['data']).isNotEmpty ? _map(json['data']) : json;
    final user = _map(root['user']).isNotEmpty ? _map(root['user']) : root;
    final role = AppRoles.canonicalRole(user['role']?.toString());
    if (role == null) throw const FormatException('Unsupported mobile role.');
    final linked = _linkedProfile(root, role);
    return UnifiedProfile(
      userId: (user['_id'] ?? user['id'] ?? '').toString(),
      profileId:
          (linked['_id'] ?? linked['id'] ?? user['profileId'] ?? '').toString(),
      email: (user['email'] ?? '').toString(),
      role: role,
      status: (user['status'] ?? user['accountStatus'] ?? '').toString(),
      accountStatus:
          (user['accountStatus'] ?? root['accountStatus'] ?? '').toString(),
      userFields: Map<String, dynamic>.unmodifiable(user),
      linkedProfileFields: Map<String, dynamic>.unmodifiable(linked),
      pointsBalance: _int(
        linked['pointsBalance'] ??
            linked['points'] ??
            root['pointsBalance'] ??
            user['pointsBalance'],
      ),
    );
  }

  static Map<String, dynamic> _linkedProfile(
    Map<String, dynamic> root,
    String role,
  ) {
    final candidates = switch (role) {
      AppRoles.household => ['resident', 'profile', 'linkedProfile'],
      AppRoles.partnerOrg => [
          'partnerOrganization',
          'profile',
          'linkedProfile'
        ],
      AppRoles.collector => ['collector', 'profile', 'linkedProfile'],
      _ => const <String>[],
    };
    for (final key in candidates) {
      final value = _map(root[key]);
      if (value.isNotEmpty) return value;
    }
    return const <String, dynamic>{};
  }

  static String? _personName(Map<String, dynamic> fields) {
    final name = [fields['firstName'], fields['lastName']]
        .map((value) => (value ?? '').toString().trim())
        .where((value) => value.isNotEmpty)
        .join(' ');
    return name.isEmpty ? null : name;
  }

  static String? _firstIdentityValue(Iterable<dynamic> values) {
    for (final value in values) {
      final text = (value ?? '').toString().trim();
      if (text.isEmpty || _isRoleLabel(text)) continue;
      return text;
    }
    return null;
  }

  static bool _isRoleLabel(String value) {
    final normalized = value.toLowerCase().replaceAll(RegExp(r'[_\s]+'), ' ');
    return const {
      'registered user',
      'partner organization',
      'partner org',
      'collector',
      'user resident',
      'user collector',
    }.contains(normalized);
  }
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? value.cast<String, dynamic>() : <String, dynamic>{};

int? _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse((value ?? '').toString());
}
