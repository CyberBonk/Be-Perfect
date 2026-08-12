import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _localeKey = 'app_locale';

class AppLocaleNotifier extends Notifier<Locale> {
  var _changedLocally = false;

  @override
  Locale build() {
    unawaited(_restore());
    final deviceLanguage =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return Locale(deviceLanguage == 'ar' ? 'ar' : 'en');
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString(_localeKey);
    if (!_changedLocally && (savedLanguage == 'ar' || savedLanguage == 'en')) {
      state = Locale(savedLanguage!);
    }
  }

  Future<void> setLanguage(String languageCode) async {
    if (languageCode != 'ar' && languageCode != 'en') return;
    _changedLocally = true;
    state = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, languageCode);
  }
}

final appLocaleProvider =
    NotifierProvider<AppLocaleNotifier, Locale>(AppLocaleNotifier.new);

extension AppTranslation on BuildContext {
  bool get isArabic => Localizations.localeOf(this).languageCode == 'ar';
  String tr(String english, String arabic) => isArabic ? arabic : english;
}
