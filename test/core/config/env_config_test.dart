import 'dart:convert';

import 'package:acendra/core/config/env_config.dart';
import 'package:flutter_test/flutter_test.dart';

String jwtWithRole(String role) =>
    'eyJhbGciOiJIUzI1NiJ9.${base64Url.encode(utf8.encode(jsonEncode({'role': role}))).replaceAll('=', '')}.fixture';

void main() {
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
