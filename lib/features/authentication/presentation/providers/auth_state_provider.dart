import 'package:acendra/core/config/env_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import 'package:supabase_flutter/supabase_flutter.dart';

final authStreamProvider = StreamProvider<AuthState>((ref) {
  if (EnvConfig.supabaseUrl.isEmpty) return const Stream.empty();
  return Supabase.instance.client.auth.onAuthStateChange;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStreamProvider).value?.session != null;
});

/// CSA-069 — exposes the current Supabase session (null when signed out).
/// Derived from the auth stream so it stays in sync with all auth events.
final currentSessionProvider = Provider<Session?>((ref) {
  return ref.watch(authStreamProvider).value?.session;
});

/// CSA-069 — true once the auth stream has emitted its first event,
/// meaning Supabase has finished restoring any persisted session.
final sessionRestoredProvider = Provider<bool>((ref) {
  return ref.watch(authStreamProvider).hasValue;
});

// Holds the email awaiting verification after sign-up.
final pendingVerificationEmailProvider = StateProvider<String?>((ref) => null);
