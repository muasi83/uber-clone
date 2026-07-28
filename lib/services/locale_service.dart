import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService {
  static const _key = 'app_locale';

  static Future<Locale> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key) ?? 'en';
    final locale = Locale(code);
    Intl.defaultLocale = code == 'ar' ? 'ar' : 'en_US';
    return locale;
  }

  static Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
    Intl.defaultLocale = locale.languageCode == 'ar' ? 'ar' : 'en_US';
  }
}
