import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads the CSA-061 RLS-protected, current-user role projection. This only
/// controls navigation visibility; backend authorization remains authoritative.
final navigationRolesLoaderProvider =
    Provider<Future<Set<String>> Function(String)>((ref) {
      return (userId) async {
        final rows = await Supabase.instance.client
            .from('user_roles')
            .select('roles!inner(code)')
            .eq('user_id', userId)
            .isFilter('revoked_at', null);
        return rows
            .map(
              (row) => (row['roles'] as Map<String, dynamic>)['code'] as String,
            )
            .toSet();
      };
    });

final navigationAccessProvider = FutureProvider.autoDispose<bool>((ref) async {
  final session = ref.watch(currentSessionProvider);
  if (session == null) return false;
  final roles = await ref.watch(navigationRolesLoaderProvider)(session.user.id);
  return roles.any(
    const {'content_manager', 'finance_admin', 'super_admin'}.contains,
  );
});
