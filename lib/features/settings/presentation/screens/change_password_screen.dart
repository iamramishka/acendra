import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/core/widgets/feedback/app_snackbar.dart';
import 'package:acendra/core/widgets/inputs/app_text_field.dart';
import 'package:acendra/features/authentication/data/auth_repository.dart';
import 'package:acendra/features/authentication/domain/auth_failure.dart';
import 'package:acendra/features/authentication/domain/auth_input_rules.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Signed-in password change; returns to Settings on success.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? get _passwordError =>
      _password.text.isNotEmpty && _password.text.length < minPasswordLength
      ? 'Password must be at least $minPasswordLength characters'
      : null;

  String? get _confirmError =>
      _confirm.text.isNotEmpty && _confirm.text != _password.text
      ? 'Passwords do not match'
      : null;

  bool get _valid =>
      _password.text.length >= minPasswordLength &&
      _confirm.text == _password.text;

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .updatePassword(newPassword: _password.text);
      if (!mounted) return;
      AppSnackbar.show(
        context,
        'Password updated.',
        variant: SnackbarVariant.success,
      );
      context.pop();
    } on AuthFailure catch (f) {
      if (mounted) {
        AppSnackbar.show(context, f.message, variant: SnackbarVariant.error);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change password')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _password,
              label: 'New password',
              obscureText: true,
              errorText: _passwordError,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _confirm,
              label: 'Confirm new password',
              obscureText: true,
              errorText: _confirmError,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Update password',
              onPressed: _loading || !_valid ? null : _submit,
              isLoading: _loading,
            ),
          ],
        ),
      ),
    );
  }
}
