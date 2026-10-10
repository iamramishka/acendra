import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/core/widgets/feedback/app_snackbar.dart';
import 'package:acendra/core/widgets/inputs/app_text_field.dart';
import 'package:acendra/core/widgets/navigation/auth_shell.dart';
import 'package:acendra/features/authentication/data/auth_repository.dart';
import 'package:acendra/features/authentication/domain/auth_failure.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _passwordError;
  String? _confirmError;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool _validate() {
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    String? pErr;
    String? cErr;

    if (password.isEmpty) {
      pErr = 'Enter a new password';
    } else if (password.length < 6) {
      pErr = 'Password must be at least 6 characters';
    }

    if (confirm.isEmpty) {
      cErr = 'Confirm your password';
    } else if (password.isNotEmpty && confirm != password) {
      cErr = 'Passwords do not match';
    }

    setState(() {
      _passwordError = pErr;
      _confirmError = cErr;
    });
    return pErr == null && cErr == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .updatePassword(newPassword: _passwordController.text);
      if (mounted) {
        AppSnackbar.show(
          context,
          'Password updated successfully.',
          variant: SnackbarVariant.success,
        );
        context.go(RouteNames.login);
      }
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Reset your password',
            style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Choose a new password for your account.', style: tt.bodyMedium),
          const SizedBox(height: 32),
          AppTextField(
            controller: _passwordController,
            label: 'New password',
            obscureText: true,
            errorText: _passwordError,
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _confirmController,
            label: 'Confirm new password',
            obscureText: true,
            errorText: _confirmError,
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Update password',
            onPressed: _isLoading ? null : _submit,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 24),
          Center(
            child: TextButton(
              onPressed: () => context.go(RouteNames.login),
              child: const Text('Back to sign in'),
            ),
          ),
        ],
      ),
    );
  }
}
