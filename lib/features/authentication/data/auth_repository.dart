import 'package:acendra/features/authentication/domain/auth_failure.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  const AuthRepository(SupabaseClient client) : _client = client;

  @visibleForTesting
  const AuthRepository.forTesting() : _client = null;

  final SupabaseClient? _client;

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      await _client!.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
    } on AuthException catch (e) {
      throw _map(e);
    } catch (_) {
      throw const NetworkError();
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _client!.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      throw _map(e);
    } catch (_) {
      throw const NetworkError();
    }
  }

  Future<void> resendVerification({required String email}) async {
    try {
      await _client!.auth.resend(type: OtpType.signup, email: email);
    } on AuthException catch (e) {
      throw _map(e);
    } catch (_) {
      throw const NetworkError();
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _client!.auth.resetPasswordForEmail(
        email,
        // The web app uses Flutter's default hash URL strategy. Preserve the
        // reset route through PKCE's code query without requiring host rewrites.
        redirectTo: Uri.base.resolve('/#/reset-password').toString(),
      );
    } on AuthException catch (e) {
      throw _map(e);
    } catch (_) {
      throw const NetworkError();
    }
  }

  Future<void> updatePassword({required String newPassword}) async {
    try {
      await _client!.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      throw _map(e);
    } catch (_) {
      throw const NetworkError();
    }
  }

  Future<void> signOut() async {
    await _client!.auth.signOut();
  }

  AuthFailure _map(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid') || msg.contains('credentials')) {
      return const InvalidCredentials();
    }
    if (msg.contains('already registered') || msg.contains('already exists')) {
      return const EmailAlreadyInUse();
    }
    if (msg.contains('email not confirmed')) {
      return const EmailNotConfirmed();
    }
    if (msg.contains('weak password') || msg.contains('password should')) {
      return const WeakPassword();
    }
    return UnexpectedAuthError(e.message);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});
