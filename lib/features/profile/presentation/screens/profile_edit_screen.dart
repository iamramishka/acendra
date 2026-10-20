import 'package:acendra/features/profile/presentation/screens/profile_screen.dart';
import 'package:flutter/material.dart';

/// Legacy edit route: view and edit were merged into [ProfileScreen] (COM-021).
class ProfileEditScreen extends StatelessWidget {
  const ProfileEditScreen({super.key});

  @override
  Widget build(BuildContext context) => const ProfileScreen();
}
