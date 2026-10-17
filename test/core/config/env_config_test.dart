import 'dart:convert';

import 'package:acendra/core/config/env_config.dart';
import 'package:flutter_test/flutter_test.dart';

String jwtWithRole(String role) =>
    'eyJhbGciOiJIUzI1NiJ9.${base64Url.encode(utf8.encode(jsonEncode({'role': role}))).replaceAll('=', '')}.fixture';

void main() {
  group('startup configuration', () {
    test('startup consumes the selected compile-time public key binding', () {
      final result = EnvConfig.readForStartup();
      if (EnvConfig.environment == 'development' &&
          EnvConfig.supabaseUrl.isEmpty &&
          EnvConfig.supabasePublicKey.isEmpty) {
        expect(result, isNull);
      } else {
        expect(result?.environment, EnvConfig.environment);
        expect(result?.url, EnvConfig.supabaseUrl);
        expect(result?.key, EnvConfig.supabasePublicKey);
      }
    });

    test('only an unconfigured development app may skip the backend', () {
      expect(
        PublicBackendConfig.forStartup(
          environment: 'development',
          url: '',
          key: '',
        ),
        isNull,
      );
      for (final environment in ['staging', 'production', 'unknown']) {
        expect(
          () => PublicBackendConfig.forStartup(
            environment: environment,
            url: '',
            key: '',
          ),
          throwsArgumentError,
        );
      }
    });

    test('partial configuration fails instead of silently skipping auth', () {
      for (final values in [
        ('http://localhost:58000', ''),
        ('', 'sb_publishable_fixture'),
      ]) {
        expect(
          () => PublicBackendConfig.forStartup(
            environment: 'development',
            url: values.$1,
            key: values.$2,
          ),
          throwsArgumentError,
        );
      }
    });

    test('hosted startup accepts public keys and rejects privileged keys', () {
      for (final environment in ['staging', 'production']) {
        for (final key in ['sb_publishable_fixture', jwtWithRole('anon')]) {
          final result = PublicBackendConfig.forStartup(
            environment: environment,
            url: 'https://example.supabase.co',
            key: key,
          );
          expect(result?.key, key);
          expect(result?.environment, environment);
        }
        expect(
          () => PublicBackendConfig.forStartup(
            environment: environment,
            url: 'https://example.supabase.co',
            key: jwtWithRole('service_role'),
          ),
          throwsArgumentError,
        );
      }
    });
  });

  PublicBackendConfig config({
    String environment = 'development',
    String url = 'http://127.0.0.1:58000',
    String key = 'sb_publishable_fixture',
  }) => PublicBackendConfig(environment: environment, url: url, key: key);

  test('local public configuration is accepted', () {
    expect(config().url, 'http://127.0.0.1:58000');
    expect(config(key: jwtWithRole('anon')).key, jwtWithRole('anon'));
  });

  test('only public key forms are accepted', () {
    for (final key in [
      '',
      'sb_secret_fixture',
      jwtWithRole('service_role'),
      jwtWithRole('authenticated'),
      'REPLACE_WITH_LOCAL_PUBLIC_KEY',
      'a.b.c',
    ]) {
      expect(() => config(key: key), throwsArgumentError);
    }
  });

  test('invalid configuration errors do not echo credentials', () {
    const secret = 'sb_secret_do_not_echo';
    try {
      config(key: secret);
      fail('Privileged key accepted');
    } on ArgumentError catch (error) {
      expect(error.toString(), isNot(contains(secret)));
    }
  });

  test('development is loopback-only and environments are explicit', () {
    expect(config(url: 'http://localhost:58000').environment, 'development');
    expect(() => config(url: 'http://example.com'), throwsArgumentError);
    expect(
      () => config(url: 'https://example.supabase.co'),
      throwsArgumentError,
    );
    expect(() => config(environment: 'unknown'), throwsArgumentError);
  });

  test('hosted environments require HTTPS without credentials', () {
    for (final environment in ['staging', 'production']) {
      expect(
        config(
          environment: environment,
          url: 'https://example.supabase.co',
        ).environment,
        environment,
      );
      expect(() => config(environment: environment), throwsArgumentError);
      expect(
        () => config(environment: environment, url: 'http://example.com'),
        throwsArgumentError,
      );
    }
    for (final url in [
      'http://user:password@localhost:58000',
      'http://localhost:58000?secret=value',
      'http://localhost:58000#fragment',
      'file:///tmp/database',
      '',
    ]) {
      expect(() => config(url: url), throwsArgumentError);
    }
  });
}
