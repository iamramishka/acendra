import 'package:acendra/features/authentication/presentation/widgets/recovery_widgets.dart';
import 'dart:async';

import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/app/theme/app_theme_extension.dart';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/core/widgets/feedback/app_snackbar.dart';
import 'package:acendra/core/widgets/navigation/auth_shell.dart';
import 'package:acendra/features/authentication/data/auth_repository.dart';
import 'package:acendra/features/authentication/domain/auth_failure.dart';
import 'package:acendra/features/authentication/domain/auth_input_rules.dart';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/authentication/presentation/widgets/auth_form_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Seconds a student must wait between verification emails.
const int resendCooldownSeconds = 30;

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final _emailController = TextEditingController();
  bool _isResending = false;
  int _secondsLeft = 0;
  Timer? _timer;
  String? _emailError;

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _secondsLeft = resendCooldownSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) t.cancel();
    });
  }

  Future<void> _resend(String? knownEmail) async {
    final email = knownEmail ?? _emailController.text.trim();
    if (!isValidEmail(email)) {
      setState(() => _emailError = 'Enter a valid email');
      return;
    }
    setState(() => _isResending = true);
    try {
      await ref.read(authRepositoryProvider).resendVerification(email: email);
      if (!mounted) return;
      _startCooldown();
      AppSnackbar.show(
        context,
        'Verification email sent.',
        variant: SnackbarVariant.success,
      );
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
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    final email = ref.watch(pendingVerificationEmailProvider);
    final coolingDown = _secondsLeft > 0;

    return AuthShell(
      onBack: () => context.go(RouteNames.login),
      banner: const RecoveryHero(icon: Icons.mail_outline, badge: Icons.check),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Check your inbox',
            style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "We've sent a verification link to your email address.",
            style: tt.bodyMedium?.copyWith(color: ext.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (email != null) ...[
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.mail_outline_rounded,
                      size: 18,
                      color: cs.primary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        maskEmail(email),
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'Open the email and follow the link to verify your account.',
            style: tt.bodySmall?.copyWith(color: ext.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (email == null) ...[
            AuthIconField(
              label: 'Email address',
              hint: 'you@example.com',
              icon: Icons.mail_outline_rounded,
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              errorText: _emailError,
              onChanged: (_) => setState(() => _emailError = null),
            ),
            const SizedBox(height: 16),
          ],
          AppButton(
            label: coolingDown
                ? 'Resend available in ${_secondsLeft}s'
                : 'Resend Verification Email',
            onPressed: (_isResending || coolingDown)
                ? null
                : () => _resend(email),
            isLoading: _isResending,
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Back to Sign In',
            variant: ButtonVariant.outlined,
            onPressed: () => context.go(RouteNames.login),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 20, color: cs.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: "Didn't receive the email? ",
                      style: const TextStyle(fontWeight: FontWeight.w700),
                      children: [
                        TextSpan(
                          text: 'Check your spam folder, or resend the link.',
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            color: ext.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    style: tt.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
