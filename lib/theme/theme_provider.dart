import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _saveThemeToPrefs();
    notifyListeners();
  }

  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }

  Future<void> _saveThemeToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
  }

  ThemeData get themeData {
    return _isDarkMode ? darkTheme : lightTheme;
  }

  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color.fromARGB(255, 219, 101, 5),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color.fromARGB(255, 219, 101, 5),
      foregroundColor: Colors.white,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      labelStyle: TextStyle(color: Colors.black87),
      border: OutlineInputBorder(),
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.black87),
    ),
  );

  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color.fromARGB(255, 219, 101, 5),
    scaffoldBackgroundColor: const Color.fromARGB(255, 14, 13, 13),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color.fromARGB(255, 219, 101, 5),
      foregroundColor: Colors.white,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      labelStyle: TextStyle(color: Colors.white),
      border: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white),
      ),
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.white),
    ),
  );
}
