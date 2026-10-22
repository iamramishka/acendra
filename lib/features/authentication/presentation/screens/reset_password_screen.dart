import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/core/widgets/feedback/app_snackbar.dart';
import 'package:acendra/core/widgets/navigation/auth_shell.dart';
import 'package:acendra/features/authentication/data/auth_repository.dart';
import 'package:acendra/features/authentication/domain/auth_failure.dart';
import 'package:acendra/features/authentication/domain/auth_input_rules.dart';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/authentication/presentation/widgets/auth_form_widgets.dart';
import 'package:acendra/features/authentication/presentation/widgets/recovery_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, this.changePassword = false});
  final bool changePassword;
  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  int _sessionRevision = 0;
  bool get _matches =>
      _password.text.isNotEmpty && _password.text == _confirm.text;
  bool get _valid => validatePassword(_password.text) == null && _matches;
  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_valid || _saving) return;
    final actor = ref.read(currentSessionProvider)?.user.id;
    final revision = _sessionRevision;
    if (actor == null) {
      if (widget.changePassword) {
        context.go(RouteNames.login);
      } else {
        AppSnackbar.show(
          context,
          'Your session has expired. Request a new password reset link.',
          variant: SnackbarVariant.error,
        );
      }
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .updatePassword(newPassword: _password.text);
      if (!mounted || !_isCurrentSession(actor, revision)) {
        return;
      }
      if (!widget.changePassword) {
        await ref.read(authRepositoryProvider).signOut();
        if (!mounted) {
          return;
        }
        // The expected recovery sign-out changes identity once, to null.
        // A different transition means this completion belongs to an old form.
        final currentActor = ref.read(currentSessionProvider)?.user.id;
        if (!_isCurrentSession(
          currentActor == null ? null : actor,
          currentActor == null ? revision + 1 : revision,
        )) {
          return;
        }
      }
      AppSnackbar.show(
        context,
        'Password updated.',
        variant: SnackbarVariant.success,
      );
      context.go(
        widget.changePassword ? RouteNames.settings : RouteNames.login,
      );
    } on AuthFailure catch (e) {
      if (mounted && _isCurrentSession(actor, revision)) {
        AppSnackbar.show(context, e.message, variant: SnackbarVariant.error);
      }
    } catch (_) {
      if (mounted && _isCurrentSession(actor, revision)) {
        AppSnackbar.show(
          context,
          'Could not update your password. Please retry.',
          variant: SnackbarVariant.error,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool _isCurrentSession(String? actor, int revision) =>
      mounted &&
      revision == _sessionRevision &&
      actor == ref.read(currentSessionProvider)?.user.id;

  @override
  Widget build(BuildContext context) {
    ref.listen(currentSessionProvider, (previous, next) {
      if (previous?.user.id == next?.user.id) return;
      _password.clear();
      _confirm.clear();
      setState(() => _sessionRevision++);
    });
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    void back() => context.go(
      widget.changePassword ? RouteNames.settings : RouteNames.login,
    );
    Widget requirement(String text, bool met) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 20,
            color: met ? cs.primary : cs.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
    return AuthShell(
      onBack: back,
      banner: const RecoveryHero(
        icon: Icons.shield_outlined,
        badge: Icons.check,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.changePassword
                ? 'Change your password'
                : 'Set a new password',
            style: tt.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a new password for your Acedra account.',
            textAlign: TextAlign.center,
            style: tt.bodyMedium,
          ),
          const SizedBox(height: 24),
          AuthPasswordField(
            key: ValueKey('password-$_sessionRevision'),
            label: 'New password',
            controller: _password,
            autofillHints: const [AutofillHints.newPassword],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          AuthPasswordField(
            key: ValueKey('confirm-$_sessionRevision'),
            label: 'Confirm new password',
            controller: _confirm,
            autofillHints: const [AutofillHints.newPassword],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Text('Your password needs', style: tt.titleSmall),
          requirement(
            'At least $minPasswordLength characters',
            _password.text.length >= minPasswordLength,
          ),
          requirement('Both passwords match', _matches),
          const SizedBox(height: 20),
          AppButton(
            label: 'Update Password',
            onPressed: _valid && !_saving ? _submit : null,
            isLoading: _saving,
          ),
          if (!widget.changePassword) ...[
            const SizedBox(height: 12),
            AppButton(
              label: 'Back to Sign In',
              variant: ButtonVariant.outlined,
              onPressed: back,
            ),
          ],
        ],
      ),
    );
  }
}
