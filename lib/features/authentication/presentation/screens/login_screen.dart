import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/app/theme/app_theme_extension.dart';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/core/widgets/feedback/app_snackbar.dart';
import 'package:acendra/core/widgets/navigation/auth_shell.dart';
import 'package:acendra/features/authentication/data/auth_repository.dart';
import 'package:acendra/features/authentication/domain/auth_failure.dart';
import 'package:acendra/features/authentication/domain/auth_input_rules.dart';
import 'package:acendra/features/authentication/presentation/widgets/auth_form_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _emailError;
  String? _passwordError;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String value) {
    if (value.trim().isEmpty) return 'Enter your email';
    if (!isValidEmail(value)) return 'Enter a valid email';
    return null;
  }

  Future<void> _submit() async {
    final emailErr = _validateEmail(_emailController.text);
    final passErr = _passwordController.text.isEmpty
        ? 'Enter your password'
        : null;
    setState(() {
      _emailError = emailErr;
      _passwordError = passErr;
    });
    if (emailErr != null || passErr != null) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (mounted) context.go(RouteNames.dashboard);
    } on AuthFailure catch (e) {
      if (mounted) {
        AppSnackbar.show(context, e.message, variant: SnackbarVariant.error);
      }
    } catch (_) {
      if (mounted) {
        AppSnackbar.show(
          context,
          'Something went wrong. Please try again.',
          variant: SnackbarVariant.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    return AuthShell(
      banner: const AuthHeroBanner(
        title: 'Welcome\nback',
        subtitle: 'Continue your learning\njourney.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Sign in to Acedra',
            style: tt.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Access your courses, track your progress\nand continue learning.',
            style: tt.bodyMedium?.copyWith(color: ext.textSecondary),
          ),
          const SizedBox(height: 24),
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
            hint: 'Enter your password',
            controller: _passwordController,
            textInputAction: TextInputAction.done,
            errorText: _passwordError,
            onChanged: (_) => setState(() => _passwordError = null),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: () => context.go(RouteNames.forgotPassword),
              child: Text(
                'Forgot password?',
                style: tt.bodySmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Sign In',
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
            prompt: 'New to Acedra?',
            actionLabel: 'Create an account',
            onTap: () => context.go(RouteNames.register),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
