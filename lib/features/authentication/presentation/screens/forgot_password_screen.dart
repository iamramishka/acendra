import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/core/widgets/feedback/app_snackbar.dart';
import 'package:acendra/core/widgets/navigation/auth_shell.dart';
import 'package:acendra/features/authentication/data/auth_repository.dart';
import 'package:acendra/features/authentication/domain/auth_failure.dart';
import 'package:acendra/features/authentication/domain/auth_input_rules.dart';
import 'package:acendra/features/authentication/presentation/widgets/auth_form_widgets.dart';
import 'package:acendra/features/authentication/presentation/widgets/recovery_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  String? _emailError;
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _validate() {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _emailError = 'Enter your email');
      return false;
    }
    if (!isValidEmail(email)) {
      setState(() => _emailError = 'Enter a valid email');
      return false;
    }
    setState(() => _emailError = null);
    return true;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .sendPasswordResetEmail(email: _emailController.text.trim());
      if (mounted) setState(() => _emailSent = true);
    } on AuthFailure catch (f) {
      if (mounted) {
        AppSnackbar.show(context, f.message, variant: SnackbarVariant.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return AuthShell(
      onBack: () => context.go(RouteNames.login),
      banner: const RecoveryHero(
        icon: Icons.lock_outline,
        badge: Icons.send_outlined,
      ),
      child: _emailSent
          ? _SuccessView(email: _emailController.text.trim())
          : _FormView(
              emailController: _emailController,
              emailError: _emailError,
              isLoading: _isLoading,
              onSubmit: _submit,
              tt: tt,
            ),
    );
  }
}

class _FormView extends StatelessWidget {
  const _FormView({
    required this.emailController,
    required this.emailError,
    required this.isLoading,
    required this.onSubmit,
    required this.tt,
  });

  final TextEditingController emailController;
  final String? emailError;
  final bool isLoading;
  final VoidCallback onSubmit;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Forgot your password?',
          style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your email and we\'ll send you a link to reset your password.',
          style: tt.bodyMedium,
        ),
        const SizedBox(height: 32),
        AuthIconField(
          controller: emailController,
          label: 'Email address',
          icon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
          errorText: emailError,
        ),
        const SizedBox(height: 16),
        AppButton(
          label: 'Send Reset Link',
          onPressed: isLoading ? null : onSubmit,
          isLoading: isLoading,
        ),
        const SizedBox(height: 24),
        AppButton(
          label: 'Back to Sign In',
          variant: ButtonVariant.outlined,
          onPressed: () => context.go(RouteNames.login),
        ),
        const SizedBox(height: 16),
        const RecoveryInfo(
          'If an account exists for the address, reset instructions will be sent.',
        ),
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.email});
  final String email;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.mark_email_read_outlined, size: 56),
        const SizedBox(height: 24),
        Text(
          'Check your inbox',
          style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'If an account exists for the address, reset instructions will be sent. Check your spam folder too.',
          style: tt.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Center(
          child: TextButton(
            onPressed: () => context.go(RouteNames.login),
            child: const Text('Back to sign in'),
          ),
        ),
      ],
    );
  }
}
