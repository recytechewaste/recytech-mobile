class PartnerOrganizationProfile {
  const PartnerOrganizationProfile({
    required this.profileId,
    required this.userId,
    required this.organizationName,
    required this.contactPerson,
    required this.contactNumber,
    required this.email,
    required this.overview,
  });

  final String profileId;
  final String userId;
  final String organizationName;
  final String contactPerson;
  final String contactNumber;
  final String email;
  final Map<String, dynamic> overview;

  factory PartnerOrganizationProfile.fromJson(Map<String, dynamic> json) {
    final profile = _object(
      json['profile'] ??
          json['partnerOrganization'] ??
          json['organization'] ??
          json['data'] ??
          json,
    );
    final user = _object(json['user']);
    final overview = _object(json['overview'] ?? profile['overview']);
    return PartnerOrganizationProfile(
      profileId: (profile['_id'] ?? profile['id'] ?? '').toString(),
      userId: (user['_id'] ?? user['id'] ?? '').toString(),
      organizationName:
          (profile['organizationName'] ?? profile['name'] ?? '').toString(),
      contactPerson: (profile['contactPerson'] ?? '').toString(),
      contactNumber:
          (profile['contactNumber'] ?? profile['phone'] ?? '').toString(),
      email: (user['email'] ?? profile['email'] ?? '').toString(),
      overview: Map<String, dynamic>.unmodifiable(overview),
    );
  }
}

class PartnerOrganizationStats {
  const PartnerOrganizationStats(this.values);

  final Map<String, dynamic> values;

  factory PartnerOrganizationStats.fromJson(Map<String, dynamic> json) {
    final values = _object(json['stats'] ?? json['data'] ?? json);
    return PartnerOrganizationStats(Map<String, dynamic>.unmodifiable(values));
  }
}

Map<String, dynamic> _object(dynamic value) =>
    value is Map ? value.cast<String, dynamic>() : <String, dynamic>{};
