import 'package:flutter/material.dart';
import 'package:sp_test/Service/theme.dart'; // Ensure this import points to your AppThemes file

class ThemeProvider with ChangeNotifier {
  ThemeData _selectedTheme;
  bool _isDarkMode;

  ThemeProvider({bool isDarkMode = false})
      : _isDarkMode = isDarkMode,
        _selectedTheme =
            isDarkMode ? AppThemes.darkTheme : AppThemes.lightTheme;

  ThemeData get getTheme => _selectedTheme;

  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _selectedTheme = _isDarkMode ? AppThemes.darkTheme : AppThemes.lightTheme;
    notifyListeners();
  }
}
