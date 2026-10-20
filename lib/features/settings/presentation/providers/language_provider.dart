import 'package:acendra/features/settings/presentation/providers/language_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Interface languages (decision D-4: English and Sinhala only).
///
/// Only the preference is stored; app-wide translation is not implemented.
enum AppLanguage {
  english('en', 'English'),
  sinhala('si', 'සිංහල');

  const AppLanguage(this.code, this.label);

  final String code;
  final String label;
}

class PreferredLanguageNotifier extends Notifier<AppLanguage> {
  @override
  AppLanguage build() {
    final saved = loadStoredLanguage();
    return AppLanguage.values.firstWhere(
      (l) => l.code == saved,
      orElse: () => AppLanguage.english,
    );
  }

  void setLanguage(AppLanguage language) {
    state = language;
    saveStoredLanguage(language.code);
  }
}

final preferredLanguageProvider =
    NotifierProvider<PreferredLanguageNotifier, AppLanguage>(
      PreferredLanguageNotifier.new,
    );
