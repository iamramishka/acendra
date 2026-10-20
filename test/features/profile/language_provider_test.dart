import 'package:acendra/features/settings/presentation/providers/language_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults to English and exposes only English and Sinhala', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(preferredLanguageProvider), AppLanguage.english);
    expect(AppLanguage.values.map((l) => l.code), ['en', 'si']);
  });

  test('setLanguage updates state', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.read(preferredLanguageProvider.notifier).setLanguage(AppLanguage.sinhala);
    expect(c.read(preferredLanguageProvider), AppLanguage.sinhala);
  });
}
