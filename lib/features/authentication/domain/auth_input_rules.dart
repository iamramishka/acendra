/// Client-side input rules for the auth forms. These only give fast feedback;
/// Supabase Auth remains the authority on what it accepts.
const int minPasswordLength = 6;

final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

bool isValidEmail(String value) => _emailPattern.hasMatch(value.trim());

/// Returns an error message, or null when [value] meets the password rule
/// (at least six characters, with no composition requirement).
String? validatePassword(String value) {
  if (value.isEmpty) return 'Enter a password';
  if (value.length < minPasswordLength) {
    return 'Use at least $minPasswordLength characters';
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
