import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/core/widgets/feedback/app_snackbar.dart';
import 'package:acendra/core/widgets/inputs/app_text_field.dart';
import 'package:acendra/core/widgets/navigation/auth_shell.dart';
import 'package:acendra/features/authentication/data/auth_repository.dart';
import 'package:acendra/features/authentication/domain/auth_failure.dart';
import 'package:acendra/features/authentication/domain/auth_input_rules.dart';
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
  bool _isLoading = false;

  bool get _lengthOk =>
      _passwordController.text.length >= minPasswordLength;

  bool get _matchOk =>
      _confirmController.text.isNotEmpty &&
      _confirmController.text == _passwordController.text;

  bool get _canSubmit => _lengthOk && _matchOk;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onChanged);
    _confirmController.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _passwordController.removeListener(_onChanged);
    _confirmController.removeListener(_onChanged);
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
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
            'Set a new password',
            style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Choose a new password for your account.', style: tt.bodyMedium),
          const SizedBox(height: 32),
          AppPasswordField(
            controller: _passwordController,
            label: 'New password',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          AppPasswordField(
            controller: _confirmController,
            label: 'Confirm new password',
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (_canSubmit) _submit();
            },
          ),
          const SizedBox(height: 16),
          _ChecklistRow(
            label: 'At least $minPasswordLength characters',
            met: _lengthOk,
          ),
          const SizedBox(height: 4),
          _ChecklistRow(
            label: 'Passwords match',
            met: _matchOk,
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Update password',
            onPressed: (_isLoading || !_canSubmit) ? null : _submit,
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

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.label, required this.met});

  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = met ? cs.primary : cs.onSurfaceVariant;
    return Row(
      children: [
        Icon(
          met
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
        ),
      ],
    );
  }
}
