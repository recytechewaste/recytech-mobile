class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String fullName;
  final String email;
  final String role;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.email,
    required this.role,
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
    );
  }
}
