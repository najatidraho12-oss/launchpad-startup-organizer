import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  static const _kDarkMode = 'darkMode';
  static const _kFontScale = 'fontScale';

  bool _darkMode = false;
  double _fontScale = 1.0;

  bool get darkMode => _darkMode;
  double get fontScale => _fontScale;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _darkMode = prefs.getBool(_kDarkMode) ?? false;
    _fontScale = prefs.getDouble(_kFontScale) ?? 1.0;
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _darkMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDarkMode, value);
  }

  Future<void> setFontScale(double value) async {
    _fontScale = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kFontScale, value);
  }
}
