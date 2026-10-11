import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/core/widgets/feedback/app_snackbar.dart';
import 'package:acendra/core/widgets/navigation/auth_shell.dart';
import 'package:acendra/features/authentication/data/auth_repository.dart';
import 'package:acendra/features/authentication/domain/auth_failure.dart';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _isResending = false;

  Future<void> _resend(String email) async {
    setState(() => _isResending = true);
    try {
      await ref.read(authRepositoryProvider).resendVerification(email: email);
      if (mounted) {
        AppSnackbar.show(
          context,
          'Verification email sent.',
          variant: SnackbarVariant.success,
        );
      }
    } on AuthFailure catch (e) {
      if (mounted) {
        AppSnackbar.show(context, e.message, variant: SnackbarVariant.error);
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final email = ref.watch(pendingVerificationEmailProvider);

    return AuthShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.mark_email_read_outlined, size: 64, color: cs.primary),
          const SizedBox(height: 24),
          Text(
            'Verify your email',
            style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            email != null
                ? 'We sent a verification link to\n$email'
                : 'Check your inbox for a verification link.',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Click the link in the email to activate your account.',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (email != null)
            AppButton(
              label: 'Resend email',
              variant: ButtonVariant.outlined,
              onPressed: _isResending ? null : () => _resend(email),
              isLoading: _isResending,
            ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Back to sign in',
            variant: ButtonVariant.secondary,
            onPressed: () => context.go(RouteNames.login),
          ),
        ],
      ),
    );
  }
}
