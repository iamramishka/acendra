import 'dart:convert';

// Public Supabase credentials are safe to embed in Flutter Web.
// Never embed service-role keys or payment secrets here.
abstract final class EnvConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static const String supabasePublicKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: supabaseAnonKey,
  );
  static const String environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  /// Call before initializing the Supabase client; never logs supplied values.
  static PublicBackendConfig read() => PublicBackendConfig(
    environment: environment,
    url: supabaseUrl,
    key: supabasePublicKey,
  );

  /// Only a completely unconfigured development build may run without a backend.
  static PublicBackendConfig? readForStartup() =>
      PublicBackendConfig.forStartup(
        environment: environment,
        url: supabaseUrl,
        key: supabasePublicKey,
      );
}

/// Public browser configuration only. This cannot verify a JWT's signature;
/// rejecting privileged key shapes prevents accidental embedding of secrets.
final class PublicBackendConfig {
  static PublicBackendConfig? forStartup({
    required String environment,
    required String url,
    required String key,
  }) {
    if (environment == 'development' && url.isEmpty && key.isEmpty) return null;
    return PublicBackendConfig(environment: environment, url: url, key: key);
  }

  PublicBackendConfig({
    required this.environment,
    required this.url,
    required this.key,
  }) {
    if (!{'development', 'staging', 'production'}.contains(environment)) {
      throw ArgumentError(
        'APP_ENV must be development, staging or production.',
      );
    }
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        !{'http', 'https'}.contains(uri.scheme)) {
      throw ArgumentError('SUPABASE_URL must be a valid backend base URL.');
    }
    final local = {'127.0.0.1', 'localhost', '[::1]', '::1'}.contains(uri.host);
    if (environment == 'development' && !local) {
      throw ArgumentError('Development must use an isolated loopback backend.');
    }
    if (environment != 'development' && (local || uri.scheme != 'https')) {
      throw ArgumentError(
        'Hosted environments require a non-loopback HTTPS URL.',
      );
    }
    if (!_isPublicKey(key)) {
      throw ArgumentError('Use a publishable key or legacy anon key only.');
    }
  }

  final String environment;
  final String url;
  final String key;

  static bool _isPublicKey(String key) {
    if (key.startsWith('sb_publishable_')) {
      return key.length > 'sb_publishable_'.length && key.trim() == key;
    }
    final parts = key.split('.');
    if (parts.length != 3 || parts.any((part) => part.isEmpty)) return false;
    try {
      final claims = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      return claims is Map<String, dynamic> && claims['role'] == 'anon';
    } on FormatException {
      return false;
    }
  }
}
