import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stable identity boundary for pending financial submissions. Token refreshes
/// do not change the actor; sign-out or account switches invalidate local work.
final checkoutActorProvider = Provider<String?>(
  (ref) => ref.watch(currentSessionProvider)?.user.id,
);
