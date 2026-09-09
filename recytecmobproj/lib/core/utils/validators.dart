String? registrationPasswordError(String password) {
  final isValid = password.length >= 8 &&
      RegExp(r'[A-Z]').hasMatch(password) &&
      RegExp(r'[a-z]').hasMatch(password) &&
      RegExp(r'[0-9]').hasMatch(password) &&
      RegExp(r'[^A-Za-z0-9]').hasMatch(password);

  return isValid
      ? null
      : 'Password must be at least 8 characters and include uppercase, lowercase, number, and special characters.';
}
