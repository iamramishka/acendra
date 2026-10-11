import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/core/widgets/feedback/app_snackbar.dart';
import 'package:acendra/core/widgets/inputs/app_text_field.dart';
import 'package:acendra/core/widgets/navigation/auth_shell.dart';
import 'package:acendra/features/authentication/data/auth_repository.dart';
import 'package:acendra/features/authentication/domain/auth_failure.dart';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
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
        : (!emailVal.contains('@') || !emailVal.contains('.'))
        ? 'Enter a valid email'
        : null;
    final pass = _passwordController.text;
    final passErr = pass.isEmpty
        ? 'Enter a password'
        : pass.length < 6
        ? 'Password must be at least 6 characters'
        : null;
    final confirmErr = _confirmPasswordController.text != pass
        ? 'Passwords do not match'
        : null;

    setState(() {
      _nameError = nameErr;
      _emailError = emailErr;
      _passwordError = passErr;
      _confirmPasswordError = confirmErr;
    });
    return nameErr == null &&
        emailErr == null &&
        passErr == null &&
        confirmErr == null;
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
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return AuthShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Create your account',
            style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Start learning today',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 32),
          AppTextField(
            label: 'Full name',
            controller: _nameController,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            errorText: _nameError,
            onChanged: (_) => setState(() => _nameError = null),
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Email',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            errorText: _emailError,
            onChanged: (_) => setState(() => _emailError = null),
          ),
          const SizedBox(height: 16),
          AppPasswordField(
            label: 'Password',
            controller: _passwordController,
            textInputAction: TextInputAction.next,
            errorText: _passwordError,
            onChanged: (_) => setState(() => _passwordError = null),
          ),
          const SizedBox(height: 16),
          AppPasswordField(
            label: 'Confirm password',
            controller: _confirmPasswordController,
            textInputAction: TextInputAction.done,
            errorText: _confirmPasswordError,
            onChanged: (_) => setState(() => _confirmPasswordError = null),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Create account',
            onPressed: _isLoading ? null : _submit,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Already have an account?', style: tt.bodyMedium),
              TextButton(
                onPressed: () => context.go(RouteNames.login),
                child: const Text('Sign in'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
