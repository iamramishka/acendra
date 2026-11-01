import 'package:acendra/app/theme/app_theme_extension.dart';
import 'package:acendra/core/widgets/inputs/app_text_field.dart';
import 'package:flutter/material.dart';

/// Navy hero card shown at the top of the sign-in and sign-up screens.
class AuthHeroBanner extends StatelessWidget {
  const AuthHeroBanner({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const RadialGradient(
          center: Alignment(0.7, -0.2),
          radius: 1.5,
          colors: [Color(0xFF1E6BFF), Color(0xFF123A9C), Color(0xFF0B1E4F)],
          stops: [0.0, 0.35, 0.75],
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showImage =
              constraints.maxWidth >= 320 &&
              MediaQuery.textScalerOf(context).scale(14) <= 21;
          final imageWidth = constraints.maxWidth * .42;
          return Stack(
            children: [
              if (showImage)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: imageWidth,
                  child: Image.asset(
                    'assets/images/signin_banner.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.centerLeft,
                    excludeFromSemantics: true,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 180),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: tt.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              subtitle,
                              style: tt.bodySmall?.copyWith(
                                color: Colors.white70,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (showImage) SizedBox(width: imageWidth + 12),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A label above a field, matching the prototype's form layout.
class AuthFieldLabel extends StatelessWidget {
  const AuthFieldLabel({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: tt.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

/// Text field with a leading icon (mail, user, ...).
class AuthIconField extends StatelessWidget {
  const AuthIconField({
    super.key,
    required this.label,
    required this.icon,
    required this.controller,
    this.hint,
    this.errorText,
    this.onChanged,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
  });

  final String label;
  final IconData icon;
  final TextEditingController controller;
  final String? hint;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    return AuthFieldLabel(
      label: label,
      child: AppTextField(
        hint: hint,
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        autofillHints: autofillHints,
        errorText: errorText,
        onChanged: onChanged,
        prefixIcon: Icon(icon, color: ext.textSecondary, size: 20),
      ),
    );
  }
}

/// Password field with a lock icon and a show/hide toggle.
class AuthPasswordField extends StatefulWidget {
  const AuthPasswordField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction = TextInputAction.next,
    this.autofillHints = const [AutofillHints.password],
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction textInputAction;
  final Iterable<String> autofillHints;

  @override
  State<AuthPasswordField> createState() => _AuthPasswordFieldState();
}

class _AuthPasswordFieldState extends State<AuthPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    return AuthFieldLabel(
      label: widget.label,
      child: AppTextField(
        hint: widget.hint,
        controller: widget.controller,
        textInputAction: widget.textInputAction,
        errorText: widget.errorText,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        keyboardType: TextInputType.visiblePassword,
        autofillHints: widget.autofillHints,
        obscureText: _obscure,
        prefixIcon: Icon(
          Icons.lock_outline_rounded,
          color: ext.textSecondary,
          size: 20,
        ),
        suffixIcon: IconButton(
          tooltip: _obscure ? 'Show password' : 'Hide password',
          icon: Icon(
            _obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 20,
            color: ext.textSecondary,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}

/// "—— or ——" divider followed by a soft card with a prompt and a link.
class AuthSwitchCard extends StatelessWidget {
  const AuthSwitchCard({
    super.key,
    required this.prompt,
    required this.actionLabel,
    required this.onTap,
  });

  final String prompt;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ext.border),
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '$prompt ',
                style: tt.bodyMedium?.copyWith(color: ext.textSecondary),
              ),
              TextButton(
                onPressed: onTap,
                child: Text(
                  actionLabel,
                  style: tt.bodyMedium?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
