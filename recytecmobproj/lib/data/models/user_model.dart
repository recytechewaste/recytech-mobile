import '../../core/constants/app_constants.dart';

class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String fullName;
  final String email;
  final String role;
  final bool emailVerified;
  final String status;
  final String accountStatus;
  final String? profileId;
  final bool isLegacyIdentity;
  final String? phone;
  final String? vehicleType;
  final String? plateNumber;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.email,
    required String role,
    this.emailVerified = true,
    String accountStatus = 'active',
    String? status,
    this.profileId,
    this.isLegacyIdentity = false,
    this.phone,
    this.vehicleType,
    this.plateNumber,
  })  : role = _requireCanonicalRole(role),
        status = (status ?? accountStatus).trim(),
        accountStatus = accountStatus.trim().toLowerCase();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final firstName = (json['firstName'] ?? '').toString();
    final lastName = (json['lastName'] ?? '').toString();
    final fullName = (json['fullName'] ??
            json['name'] ??
            [firstName, lastName].where((part) => part.isNotEmpty).join(' '))
        .toString();
    final rawRole = (json['role'] ?? '').toString();
    final canonicalRole = AppRoles.canonicalRole(rawRole);
    if (canonicalRole == null) {
      throw const FormatException('Unsupported mobile role.');
    }
    final isLegacyIdentity =
        json['isLegacyIdentity'] == true || !AppRoles.isCanonical(rawRole);
    final profileId = _optionalString(json['profileId']);
    return UserModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      firstName: firstName,
      lastName: lastName,
      fullName: fullName,
      email: (json['email'] ?? '').toString(),
      role: canonicalRole,
      emailVerified: json['emailVerified'] is bool
          ? json['emailVerified'] as bool
          : json['isEmailVerified'] is bool
              ? json['isEmailVerified'] as bool
              : true,
      status: (json['status'] ?? json['accountStatus'] ?? '').toString(),
      accountStatus: (json['accountStatus'] ?? json['status'] ?? 'active')
          .toString()
          .trim()
          .toLowerCase(),
      profileId: profileId,
      isLegacyIdentity: isLegacyIdentity,
      phone: _optionalString(
        json['phone'] ??
            json['contactNumber'] ??
            json['contact_number'] ??
            json['mobile'] ??
            json['mobileNumber'],
      ),
      vehicleType: _optionalString(
        json['vehicleType'] ?? json['vehicle_type'] ?? json['vehicle'],
      ),
      plateNumber: _optionalString(
        json['plateNumber'] ?? json['plate_number'] ?? json['plateNo'],
      ),
    );
  }

  factory UserModel.fromSessionJson(Map<String, dynamic> json) {
    final user = UserModel.fromJson(json);
    if (user.profileId == null && !user.isLegacyIdentity) {
      throw const FormatException(
        'Canonical mobile identity is missing its profile ID.',
      );
    }
    return user;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'fullName': fullName,
      'email': email,
      'role': role,
      'emailVerified': emailVerified,
      'status': status,
      'accountStatus': accountStatus,
      if (profileId != null) 'profileId': profileId,
      if (isLegacyIdentity) 'isLegacyIdentity': true,
      if (phone != null) 'phone': phone,
      if (vehicleType != null) 'vehicleType': vehicleType,
      if (plateNumber != null) 'plateNumber': plateNumber,
    };
  }

  static String? _optionalString(dynamic value) {
    final text = (value ?? '').toString().trim();
    return text.isEmpty ? null : text;
  }

  static String _requireCanonicalRole(String role) {
    if (!AppRoles.isCanonical(role)) {
      throw ArgumentError.value(role, 'role', 'Role must be canonical');
    }
    return role;
  }
}
