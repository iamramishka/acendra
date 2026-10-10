import 'package:acendra/core/config/env_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authStreamProvider = StreamProvider<AuthState>((ref) {
  if (EnvConfig.supabaseUrl.isEmpty) return const Stream.empty();
  return Supabase.instance.client.auth.onAuthStateChange;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStreamProvider).valueOrNull?.session != null;
});

// Holds the email awaiting verification after sign-up.
final pendingVerificationEmailProvider = StateProvider<String?>((ref) => null);
