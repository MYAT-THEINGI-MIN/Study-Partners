bool isStrongPassword(String password) {
  // Regular expressions for password strength
  RegExp upperCase = RegExp(r'[A-Z]');
  RegExp lowerCase = RegExp(r'[a-z]');
  RegExp digit = RegExp(r'[0-9]');
  RegExp specialChars = RegExp(r'(?=.*[@#$%^&+=])');

  // Check if password meets all requirements
  return upperCase.hasMatch(password) &&
      lowerCase.hasMatch(password) &&
      digit.hasMatch(password) &&
      specialChars.hasMatch(password);
}
