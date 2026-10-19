import 'package:acendra/app/router/route_names.dart';
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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _termsError;
  bool _acceptedTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validate() {
    final nameErr = _nameController.text.trim().isEmpty
        ? 'Enter your full name'
        : null;
    final emailVal = _emailController.text.trim();
    final emailErr = emailVal.isEmpty
        ? 'Enter your email'
        : !isValidEmail(emailVal)
        ? 'Enter a valid email'
        : null;
    final pass = _passwordController.text;
    final passErr = validatePassword(pass);
    final confirmErr = _confirmPasswordController.text != pass
        ? 'Passwords do not match'
        : null;
    final termsErr = _acceptedTerms
        ? null
        : 'Accept the terms to create an account.';

    setState(() {
      _nameError = nameErr;
      _emailError = emailErr;
      _passwordError = passErr;
      _confirmPasswordError = confirmErr;
      _termsError = termsErr;
    });
    return nameErr == null &&
        emailErr == null &&
        passErr == null &&
        confirmErr == null &&
        termsErr == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;

    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      await ref
          .read(authRepositoryProvider)
          .signUp(
            email: email,
            password: _passwordController.text,
            fullName: _nameController.text.trim(),
          );
      ref.read(pendingVerificationEmailProvider.notifier).state = email;
      if (mounted) context.go(RouteNames.verifyEmail);
    } on AuthFailure catch (e) {
      if (mounted) {
        AppSnackbar.show(context, e.message, variant: SnackbarVariant.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return AuthShell(
      onBack: () => context.go(RouteNames.login),
      banner: const AuthHeroBanner(
        title: 'Create your\naccount',
        subtitle: 'Start learning with\nconfidence.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthIconField(
            label: 'Full name',
            hint: 'Enter your name',
            icon: Icons.person_outline_rounded,
            controller: _nameController,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            errorText: _nameError,
            onChanged: (_) => setState(() => _nameError = null),
          ),
          const SizedBox(height: 16),
          AuthIconField(
            label: 'Email address',
            hint: 'you@example.com',
            icon: Icons.mail_outline_rounded,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            errorText: _emailError,
            onChanged: (_) => setState(() => _emailError = null),
          ),
          const SizedBox(height: 16),
          AuthPasswordField(
            label: 'Password',
            hint: 'At least $minPasswordLength characters',
            controller: _passwordController,
            autofillHints: const [AutofillHints.newPassword],
            errorText: _passwordError,
            onChanged: (_) => setState(() => _passwordError = null),
          ),
          const SizedBox(height: 16),
          AuthPasswordField(
            label: 'Confirm password',
            hint: 'Re-enter your password',
            controller: _confirmPasswordController,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            errorText: _confirmPasswordError,
            onChanged: (_) => setState(() => _confirmPasswordError = null),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            value: _acceptedTerms,
            onChanged: (v) => setState(() {
              _acceptedTerms = v ?? false;
              _termsError = null;
            }),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text.rich(
              TextSpan(
                text: 'I agree to the ',
                children: [
                  TextSpan(
                    text: 'Terms of Service',
                    style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
              style: tt.bodySmall?.copyWith(color: cs.onSurface),
            ),
          ),
          if (_termsError != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: cs.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _termsError!,
                      style: tt.bodySmall?.copyWith(color: cs.error),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          AppButton(
            label: 'Create Account',
            size: ButtonSize.large,
            onPressed: _isLoading ? null : _submit,
            isLoading: _isLoading,
            icon: _isLoading
                ? null
                : Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: cs.onPrimary,
                  ),
          ),
          const SizedBox(height: 20),
          AuthSwitchCard(
            prompt: 'Already have an account?',
            actionLabel: 'Sign In',
            onTap: () => context.go(RouteNames.login),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
