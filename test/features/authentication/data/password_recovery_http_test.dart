import 'dart:convert';
import 'dart:io';

import 'package:acendra/features/authentication/data/auth_repository.dart';
import 'package:acendra/features/authentication/domain/auth_failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MemoryStorage extends GotrueAsyncStorage {
  final _values = <String, String>{};
  @override
  Future<String?> getItem({required String key}) async => _values[key];
  @override
  Future<void> setItem({required String key, required String value}) async {
    _values[key] = value;
  }

  @override
  Future<void> removeItem({required String key}) async => _values.remove(key);
}

void main() {
  late HttpServer server;
  late SupabaseClient client;
  late AuthRepository repository;
  late List<({String method, Uri uri, Map<String, dynamic> body, String? auth})>
  requests;
  late List<AuthChangeEvent> events;
  var rejectCode = false;
  var rejectEmail = false;
  final user = {
    'id': 'synthetic-student',
    'aud': 'authenticated',
    'role': 'authenticated',
    'email': 'student@example.com',
    'app_metadata': <String, dynamic>{},
    'user_metadata': <String, dynamic>{},
    'created_at': '2026-11-01T00:00:00Z',
  };

  setUp(() async {
    rejectCode = false;
    rejectEmail = false;
    requests = [];
    events = [];
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final text = await utf8.decoder.bind(request).join();
      requests.add((
        method: request.method,
        uri: request.uri,
        body: text.isEmpty ? {} : jsonDecode(text) as Map<String, dynamic>,
        auth: request.headers.value('authorization'),
      ));
      request.response.headers.contentType = ContentType.json;
      Object response = {};
      if (request.uri.path == '/auth/v1/token') {
        if (rejectCode) {
          request.response.statusCode = 400;
          response = {
            'code': 'flow_state_expired',
            'msg': 'Flow state has expired',
          };
        } else {
          response = {
            'access_token': 'synthetic-access-token',
            'refresh_token': 'synthetic-refresh-token',
            'token_type': 'bearer',
            'expires_in': 3600,
            'user': user,
          };
        }
      } else if (request.uri.path == '/auth/v1/user') {
        response = user;
      } else if (request.uri.path == '/auth/v1/recover' && rejectEmail) {
        request.response.statusCode = 429;
        response = {'code': 'over_email_send_rate_limit', 'msg': 'Rate limit'};
      } else if (request.uri.path != '/auth/v1/recover' &&
          request.uri.path != '/auth/v1/logout') {
        request.response.statusCode = 404;
        response = {'msg': 'Unexpected test endpoint'};
      }
      request.response.write(jsonEncode(response));
      await request.response.close();
    });
    client = SupabaseClient(
      'http://127.0.0.1:${server.port}',
      'synthetic-publishable-key',
      authOptions: AuthClientOptions(
        autoRefreshToken: false,
        authFlowType: AuthFlowType.pkce,
        pkceAsyncStorage: _MemoryStorage(),
      ),
    );
    repository = AuthRepository(client);
    final subscription = client.auth.onAuthStateChange.listen(
      (state) => events.add(state.event),
    );
    addTearDown(subscription.cancel);
  });

  tearDown(() async {
    await client.dispose();
    await server.close(force: true);
  });

  test(
    'recovery email sends reset route and PKCE without creating a session',
    () async {
      await repository.sendPasswordResetEmail(email: 'student@example.com');
      final request = requests.single;
      expect(request.method, 'POST');
      expect(request.uri.path, '/auth/v1/recover');
      final redirect = Uri.parse(request.uri.queryParameters['redirect_to']!);
      expect(redirect.fragment, '/reset-password');
      expect(redirect.scheme, Uri.base.scheme);
      expect(redirect.host, Uri.base.host);
      expect(request.body['email'], 'student@example.com');
      expect(request.body['code_challenge_method'], 's256');
      expect(request.body['code_challenge'], isNotEmpty);
      expect(request.body.containsKey('password'), isFalse);
      expect(client.auth.currentSession, isNull);
    },
  );

  test(
    'valid reset code establishes recovery session and allows update then sign out',
    () async {
      await repository.sendPasswordResetEmail(email: 'student@example.com');
      final recoveryEvent = client.auth.onAuthStateChange.firstWhere(
        (state) => state.event == AuthChangeEvent.passwordRecovery,
      );
      await client.auth.getSessionFromUrl(
        Uri.parse(
          'https://example.com/?code=synthetic-valid-code#/reset-password',
        ),
      );
      expect((await recoveryEvent).session?.user.id, 'synthetic-student');
      expect(requests.last.uri.queryParameters['grant_type'], 'pkce');
      expect(requests.last.body['auth_code'], 'synthetic-valid-code');
      expect(requests.last.body['code_verifier'], isNotEmpty);
      await repository.updatePassword(newPassword: 'abcdef');
      expect(requests.last.method, 'PUT');
      expect(requests.last.uri.path, '/auth/v1/user');
      expect(requests.last.auth, 'Bearer synthetic-access-token');
      expect(requests.last.body['password'], 'abcdef');
      await repository.signOut();
      expect(requests.last.uri.path, '/auth/v1/logout');
      expect(client.auth.currentSession, isNull);
    },
  );

  test(
    'expired reset code cannot establish session or update password',
    () async {
      await repository.sendPasswordResetEmail(email: 'student@example.com');
      rejectCode = true;
      await expectLater(
        client.auth.getSessionFromUrl(
          Uri.parse(
            'https://example.com/?code=synthetic-expired-code#/reset-password',
          ),
        ),
        throwsA(isA<AuthException>()),
      );
      expect(client.auth.currentSession, isNull);
      expect(events, isNot(contains(AuthChangeEvent.passwordRecovery)));
      await expectLater(
        repository.updatePassword(newPassword: 'abcdef'),
        throwsA(isA<AuthFailure>()),
      );
      expect(requests.where((r) => r.uri.path == '/auth/v1/user'), isEmpty);
    },
  );

  test('signed-in password change keeps the existing session', () async {
    await client.auth.signInWithPassword(
      email: 'student@example.com',
      password: 'old-synthetic',
    );
    final before = client.auth.currentSession!;
    requests.clear();
    await repository.updatePassword(newPassword: 'abcdef');
    expect(requests.single.uri.path, '/auth/v1/user');
    expect(requests.single.body['password'], 'abcdef');
    expect(requests.single.auth, 'Bearer synthetic-access-token');
    expect(client.auth.currentSession?.user.id, before.user.id);
    expect(client.auth.currentSession?.accessToken, before.accessToken);
  });

  test(
    'email rejection is a failure, not a successful recovery request',
    () async {
      rejectEmail = true;
      await expectLater(
        repository.sendPasswordResetEmail(email: 'student@example.com'),
        throwsA(isA<AuthFailure>()),
      );
      expect(client.auth.currentSession, isNull);
    },
  );
}
