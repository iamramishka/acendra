import 'dart:convert';

import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A navigation hint only. Finance operations still enforce roles and MFA on
/// the backend. Read current grants through the existing own-role RLS policy.
final financeAccessProvider = FutureProvider<bool>((ref) async {
  final session = ref.watch(currentSessionProvider);
  if (session == null) return false;
  try {
    final parts = session.accessToken.split('.');
    if (parts.length != 3) return false;
    final claims = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
    if (claims is! Map<String, dynamic> || claims['aal'] != 'aal2') {
      return false;
    }
    final grants = await ref.watch(financeRoleGrantsProvider.future);
    return grants.any(
      (role) => role == 'finance_admin' || role == 'super_admin',
    );
  } on FormatException {
    return false;
  }
});

final financeRoleGrantsProvider = FutureProvider<List<String>>((ref) async {
  final session = ref.watch(currentSessionProvider);
  if (session == null) return const [];
  final rows = await Supabase.instance.client
      .from('user_roles')
      .select('roles!inner(code)')
      .eq('user_id', session.user.id)
      .isFilter('revoked_at', null);
  return rows.map((row) => (row['roles'] as Map)['code'] as String).toList();
});
