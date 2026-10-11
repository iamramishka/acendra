import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/core/widgets/feedback/app_snackbar.dart';
import 'package:acendra/core/widgets/inputs/app_text_field.dart';
import 'package:acendra/features/profile/presentation/providers/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _nameController = TextEditingController();
  String? _nameError;

  @override
  void initState() {
    super.initState();
    final current = ref.read(displayNameProvider);
    if (current != null) _nameController.text = current;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Display name cannot be empty');
      return;
    }
    setState(() => _nameError = null);

    await ref
        .read(profileEditProvider.notifier)
        .updateDisplayName(displayName: name);

    if (!mounted) return;

    final state = ref.read(profileEditProvider);
    if (state.hasError) {
      final failure = profileEditError(state);
      AppSnackbar.show(
        context,
        failure?.message ?? 'Could not update profile',
        variant: SnackbarVariant.error,
      );
    } else {
      AppSnackbar.show(
        context,
        'Profile updated',
        variant: SnackbarVariant.success,
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(profileEditProvider).isLoading;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Update your display name',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            AppTextField(
              label: 'Display name',
              controller: _nameController,
              textInputAction: TextInputAction.done,
              errorText: _nameError,
              onChanged: (_) => setState(() => _nameError = null),
              onSubmitted: (_) => isLoading ? null : _submit(),
            ),
            const SizedBox(height: 32),
            AppButton(
              label: 'Save changes',
              onPressed: isLoading ? null : _submit,
              isLoading: isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
