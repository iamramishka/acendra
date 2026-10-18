import 'package:acendra/features/authentication/presentation/screens/reset_password_screen.dart';
import 'package:flutter/widgets.dart';

/// Reuses the account password policy and preserves the signed-in session.
class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const ResetPasswordScreen(changePassword: true);
}
