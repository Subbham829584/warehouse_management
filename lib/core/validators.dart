class Validators {
  Validators._();

  static final RegExp _email = RegExp(r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,}$');

  static String? required(String? v, [String field = 'This field']) =>
      (v == null || v.trim().isEmpty) ? '$field is required' : null;

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    return _email.hasMatch(v.trim()) ? null : 'Enter a valid email';
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Use at least 8 characters';
    return null;
  }

  static String? nonNegativeInt(String? v, [String field = 'Value']) {
    if (v == null || v.trim().isEmpty) return '$field is required';
    final n = int.tryParse(v.trim());
    if (n == null) return '$field must be a whole number';
    if (n < 0) return '$field cannot be negative';
    return null;
  }

  static String? nonNegativeNumber(String? v, [String field = 'Value']) {
    if (v == null || v.trim().isEmpty) return '$field is required';
    final n = double.tryParse(v.trim());
    if (n == null) return '$field must be a number';
    if (n < 0) return '$field cannot be negative';
    return null;
  }
}
