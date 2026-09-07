class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String fullName;
  final String email;
  final String role;
  final bool emailVerified;
  final String accountStatus;
  final String? phone;
  final String? vehicleType;
  final String? plateNumber;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.email,
    required this.role,
    this.emailVerified = true,
    this.accountStatus = 'active',
    this.phone,
    this.vehicleType,
    this.plateNumber,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final firstName = (json['firstName'] ?? '').toString();
    final lastName = (json['lastName'] ?? '').toString();
    final fullName = (json['fullName'] ??
            json['name'] ??
            [firstName, lastName].where((part) => part.isNotEmpty).join(' '))
        .toString();

    return UserModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      firstName: firstName,
      lastName: lastName,
      fullName: fullName,
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      emailVerified: json['emailVerified'] is bool
          ? json['emailVerified'] as bool
          : json['isEmailVerified'] is bool
              ? json['isEmailVerified'] as bool
              : true,
      accountStatus: (json['accountStatus'] ?? json['status'] ?? 'active')
          .toString()
          .trim()
          .toLowerCase(),
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'fullName': fullName,
      'email': email,
      'role': role,
      'emailVerified': emailVerified,
      'accountStatus': accountStatus,
      if (phone != null) 'phone': phone,
      if (vehicleType != null) 'vehicleType': vehicleType,
      if (plateNumber != null) 'plateNumber': plateNumber,
    };
  }

  static String? _optionalString(dynamic value) {
    final text = (value ?? '').toString().trim();
    return text.isEmpty ? null : text;
  }
}
