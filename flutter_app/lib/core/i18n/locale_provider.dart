import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_strings.dart';
import 'kk.dart';
import 'ru.dart';

enum AppLocale { kk, ru }

const _prefsKey = 'juma_ui_locale';

/// Persists the chosen locale the same way the web app persists dark
/// mode (localStorage key, mirrored here via SharedPreferences) — see
/// KAZAKH_LOCALIZATION.md's "Locale-switching UX" section. Defaults to
/// Kazakh; the app never auto-detects device/browser language.
class LocaleController extends Notifier<AppLocale> {
  @override
  AppLocale build() {
    _restore();
    return AppLocale.kk;
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved == AppLocale.ru.name) {
      state = AppLocale.ru;
    }
  }

  Future<void> setLocale(AppLocale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.name);
  }
}

final localeProvider = NotifierProvider<LocaleController, AppLocale>(
  LocaleController.new,
);

final appStringsProvider = Provider<AppStrings>((ref) {
  final locale = ref.watch(localeProvider);
  return switch (locale) {
    AppLocale.kk => const KkStrings(),
    AppLocale.ru => const RuStrings(),
  };
});
