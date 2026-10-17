import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/app/theme/app_colors.dart';
import 'package:acendra/app/theme/app_theme_extension.dart';
import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/core/widgets/feedback/app_snackbar.dart';
import 'package:acendra/core/widgets/inputs/app_text_field.dart';
import 'package:acendra/core/widgets/navigation/auth_shell.dart';
import 'package:acendra/features/authentication/data/auth_repository.dart';
import 'package:acendra/features/authentication/domain/auth_failure.dart';
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
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String value) {
    if (value.trim().isEmpty) return 'Enter your email';
    if (!value.contains('@') || !value.contains('.')) {
      return 'Enter a valid email';
    }
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
      banner: _SignInBanner(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Heading
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

          // Email field
          Text(
            'Email address',
            style: tt.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          AppTextField(
            hint: 'you@example.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            errorText: _emailError,
            onChanged: (_) => setState(() => _emailError = null),
            prefixIcon: Icon(
              Icons.mail_outline_rounded,
              color: ext.textSecondary,
              size: 20,
            ),
          ),
          const SizedBox(height: 16),

          // Password field
          Text(
            'Password',
            style: tt.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          _PasswordFieldWithIcon(
            controller: _passwordController,
            errorText: _passwordError,
            onChanged: (_) => setState(() => _passwordError = null),
            textSecondaryColor: ext.textSecondary,
          ),
          const SizedBox(height: 12),

          // Remember me + Forgot password
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: _rememberMe,
                      onChanged: (v) =>
                          setState(() => _rememberMe = v ?? false),
                      activeColor: cs.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Remember me',
                    style: tt.bodySmall?.copyWith(color: cs.onSurface),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => context.go(RouteNames.forgotPassword),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Forgot password?',
                  style: tt.bodySmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Sign In button
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

          // "or" divider
          Row(
            children: [
              Expanded(child: Divider(color: ext.border)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'or',
                  style: tt.bodySmall?.copyWith(color: ext.textSecondary),
                ),
              ),
              Expanded(child: Divider(color: ext.border)),
            ],
          ),
          const SizedBox(height: 16),

          // Create account row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ext.border),
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 8,
              children: [
                Text(
                  'New to Acedra? ',
                  style: tt.bodyMedium?.copyWith(color: ext.textSecondary),
                ),
                GestureDetector(
                  onTap: () => context.go(RouteNames.register),
                  child: Text(
                    'Create an account',
                    style: tt.bodyMedium?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Privacy / Terms footer
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            children: [
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Privacy Policy',
                  style: tt.bodySmall?.copyWith(color: ext.textSecondary),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '·',
                  style: tt.bodySmall?.copyWith(color: ext.textSecondary),
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Terms of Service',
                  style: tt.bodySmall?.copyWith(color: ext.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// Banner: dark navy card with welcome text + hero image
class _SignInBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.deepNavy,
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // Welcome text
          Positioned(
            left: 20,
            top: 0,
            bottom: 0,
            width: 160,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome\nback',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Continue your learning\njourney.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          // Hero image
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 200,
            child: Image.asset(
              'assets/images/signin_banner.png',
              fit: BoxFit.cover,
              alignment: Alignment.centerLeft,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

// Password field with lock prefix icon
class _PasswordFieldWithIcon extends StatefulWidget {
  const _PasswordFieldWithIcon({
    required this.controller,
    required this.errorText,
    required this.onChanged,
    required this.textSecondaryColor,
  });

  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String> onChanged;
  final Color textSecondaryColor;

  @override
  State<_PasswordFieldWithIcon> createState() => _PasswordFieldWithIconState();
}

class _PasswordFieldWithIconState extends State<_PasswordFieldWithIcon> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      hint: 'Enter your password',
      controller: widget.controller,
      textInputAction: TextInputAction.done,
      errorText: widget.errorText,
      onChanged: widget.onChanged,
      keyboardType: TextInputType.visiblePassword,
      autofillHints: const [AutofillHints.password],
      obscureText: _obscure,
      prefixIcon: Icon(
        Icons.lock_outline_rounded,
        color: widget.textSecondaryColor,
        size: 20,
      ),
      suffixIcon: IconButton(
        tooltip: _obscure ? 'Show password' : 'Hide password',
        icon: Icon(
          _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          size: 20,
          color: widget.textSecondaryColor,
        ),
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
    );
  }
}
