import 'package:flutter/material.dart';

class AppSettings extends ChangeNotifier {
  Locale _locale = const Locale('ru');
  ThemeMode _themeMode = ThemeMode.light;

  Locale get locale => _locale;
  ThemeMode get themeMode => _themeMode;

  void setLocale(Locale newLocale) {
    _locale = newLocale;
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}
