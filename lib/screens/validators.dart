final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
final _indianMobile = RegExp(r'^[6-9]\d{9}$');

String? validateName(String? value) =>
    (value == null || value.trim().length < 2) ? 'Enter your name' : null;

String? validateEmail(String? value) =>
    (value == null || !_emailPattern.hasMatch(value.trim()))
        ? 'Enter a valid email address'
        : null;

String? validatePassword(String? value) =>
    (value == null || value.length < 6)
        ? 'Password must be at least 6 characters'
        : null;

String? validateMobile(String? value) =>
    (value == null || !_indianMobile.hasMatch(value.trim()))
        ? 'Enter a valid 10-digit mobile number'
        : null;
