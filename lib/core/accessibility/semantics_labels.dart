/// Centralised semantic label constants used across the design system.
///
/// Keeps screen-reader strings in one place so they stay consistent and
/// are easy to update without hunting through widget files.
abstract final class SemanticsLabels {
  // Navigation
  static const String openMenu = 'Open navigation menu';
  static const String closeMenu = 'Close navigation menu';
  static const String skipToContent = 'Skip to main content';

  // Theme
  static const String switchToLight = 'Switch to light theme';
  static const String switchToDark = 'Switch to dark theme';

  // Password field
  static const String showPassword = 'Show password';
  static const String hidePassword = 'Hide password';

  // Loading states
  static String loadingButton(String label) => '$label, loading';
}
