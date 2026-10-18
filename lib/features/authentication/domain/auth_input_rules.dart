/// Client-side input rules for the auth forms. These only give fast feedback;
/// Supabase Auth remains the authority on what it accepts.
const int minPasswordLength = 8;

final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

bool isValidEmail(String value) => _emailPattern.hasMatch(value.trim());

/// Returns an error message, or null when [value] meets the password rule
/// (8+ characters with at least one letter and one number).
String? validatePassword(String value) {
  if (value.isEmpty) return 'Enter a password';
  if (value.length < minPasswordLength ||
      !RegExp(r'[A-Za-z]').hasMatch(value) ||
      !RegExp(r'\d').hasMatch(value)) {
    return 'Use at least $minPasswordLength characters with a letter and a number';
  }
  return null;
}

/// `demo@example.com` -> `de••@example.com`.
String maskEmail(String email) {
  final at = email.indexOf('@');
  if (at <= 0) return email;
  final local = email.substring(0, at);
  final keep = local.length <= 2 ? 1 : 2;
  return '${local.substring(0, keep)}${'•' * (local.length - keep).clamp(1, 2)}'
      '${email.substring(at)}';
}
