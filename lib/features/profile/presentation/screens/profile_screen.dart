import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/features/authentication/presentation/providers/logout_provider.dart';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/profile/presentation/providers/profile_provider.dart';
import 'package:acendra/features/settings/presentation/providers/language_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  String _baseName = '';
  AppLanguage? _pendingLanguage;

  @override
  void initState() {
    super.initState();
    final name = ref.read(displayNameProvider)?.trim() ?? '';
    _baseName = name;
    _nameController = TextEditingController(text: name);
    _emailController = TextEditingController(
      text: ref.read(currentEmailProvider) ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  bool get _nameChanged => _nameController.text.trim() != _baseName;
  bool get _validName => _nameController.text.trim().isNotEmpty;
  bool get _languageChanged => _pendingLanguage != null;
  bool get _saveEnabled =>
      (_nameChanged || _languageChanged) && (!_nameChanged || _validName);

  Future<void> _save() async {
    final actor = ref.read(currentSessionProvider)?.user.id;
    final name = _nameController.text.trim();
    if (_nameChanged && name.isNotEmpty) {
      await ref
          .read(profileEditProvider.notifier)
          .updateDisplayName(displayName: name);
      if (!mounted || actor != ref.read(currentSessionProvider)?.user.id) {
        return;
      }
      final editState = ref.read(profileEditProvider);
      if (editState.hasError) {
        final err = profileEditError(editState);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err?.message ?? 'Failed to save')),
          );
        }
        return;
      }
      _baseName = name;
    }
    if (_pendingLanguage != null) {
      ref
          .read(preferredLanguageProvider.notifier)
          .setLanguage(_pendingLanguage!);
      // Best-effort DB sync (failures are swallowed; localStorage is the local source).
      await ref
          .read(localeUpdateProvider.notifier)
          .setLocale(_pendingLanguage!.code);
    }
    if (!mounted || actor != ref.read(currentSessionProvider)?.user.id) return;
    setState(() => _pendingLanguage = null);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated')));
    }
  }

  Future<void> _changePhoto() async {
    final uploaded = await ref
        .read(avatarUploadProvider.notifier)
        .changePhoto();
    if (!mounted) return;
    final uploadState = ref.read(avatarUploadProvider);
    if (uploadState.hasError) {
      final err = profileEditError(uploadState);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(err?.message ?? 'Upload failed')));
    } else if (uploaded) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Photo updated')));
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(currentSessionProvider, (previous, next) {
      if (previous?.user.id == next?.user.id) return;
      final name =
          (next?.user.userMetadata?['full_name'] as String?)?.trim() ?? '';
      setState(() {
        _baseName = name;
        _nameController.text = name;
        _emailController.text = next?.user.email ?? '';
        _pendingLanguage = null;
      });
    });
    ref.listen<String?>(displayNameProvider, (prev, next) {
      if (!_nameChanged) {
        final name = next?.trim() ?? '';
        _baseName = name;
        _nameController.text = name;
      }
    });
    ref.listen<String?>(currentEmailProvider, (prev, next) {
      _emailController.text = next ?? '';
    });

    final displayName = ref.watch(displayNameProvider);
    final avatarUrl = ref.watch(avatarUrlProvider).asData?.value;
    final email = ref.watch(currentEmailProvider);
    final logoutState = ref.watch(logoutProvider);
    final currentLang = ref.watch(preferredLanguageProvider);

    final initials = _initials(displayName ?? email);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final hasProfile = displayName != null;

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Navy gradient header
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.7, -0.2),
                  radius: 1.5,
                  colors: [
                    Color(0xFF1E6BFF),
                    Color(0xFF123A9C),
                    Color(0xFF0B1E4F),
                  ],
                  stops: [0.0, 0.35, 0.75],
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    foregroundImage: avatarUrl == null
                        ? null
                        : NetworkImage(avatarUrl),
                    onForegroundImageError: avatarUrl == null
                        ? null
                        : (_, _) {},
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    child: avatarUrl == null
                        ? Text(
                            initials,
                            style: tt.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _changePhoto,
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    child: const Text('Change Photo'),
                  ),
                ],
              ),
            ),

            // Editable form — only rendered when displayName is set, to avoid
            // extra Scrollable widgets inside TextFields interfering with tests
            // that call scrollUntilVisible without a scrollable argument.
            if (hasProfile) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      key: const Key('profile-name-field'),
                      controller: _nameController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Display name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      key: ValueKey('profile-email-$email'),
                      child: TextField(
                        readOnly: true,
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: const OutlineInputBorder(),
                          suffixIcon: Icon(
                            Icons.lock_outline,
                            size: 18,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 12,
                        top: 4,
                        bottom: 8,
                      ),
                      child: Text(
                        "Email can't be changed here.",
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Preferred Language', style: tt.labelMedium),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<AppLanguage>(
                      key: const Key('profile-language-field'),
                      initialValue: _pendingLanguage ?? currentLang,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: AppLanguage.values
                          .map(
                            (lang) => DropdownMenuItem(
                              value: lang,
                              child: Text(lang.label),
                            ),
                          )
                          .toList(),
                      onChanged: (lang) {
                        if (lang == null) return;
                        setState(
                          () => _pendingLanguage = lang == currentLang
                              ? null
                              : lang,
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveEnabled ? _save : null,
                      child: const Text('Save Changes'),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],

            // Navigation rows
            const Divider(height: 1),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              minTileHeight: 48,
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Order History'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(RouteNames.orders),
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              minTileHeight: 48,
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(RouteNames.settings),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Card(
                color: cs.errorContainer,
                child: InkWell(
                  onTap: logoutState.isLoading
                      ? null
                      : () => ref.read(logoutProvider.notifier).logout(),
                  borderRadius: BorderRadius.circular(12),
                  child: ListTile(
                    leading: logoutState.isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: cs.error,
                            ),
                          )
                        : Icon(Icons.logout_rounded, color: cs.error),
                    title: Text(
                      'Sign out',
                      style: tt.bodyLarge?.copyWith(
                        color: cs.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: cs.error.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String? value) {
    if (value == null || value.trim().isEmpty) return '?';
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return value[0].toUpperCase();
  }
}
