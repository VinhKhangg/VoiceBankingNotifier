import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system; // Mặc định theo hệ thống

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadTheme(); // Tải theme đã lưu khi khởi tạo
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('isDarkMode');
    if (isDarkMode == null) {
      _themeMode = ThemeMode.system; // Nếu chưa có cài đặt, dùng theme hệ thống
    } else {
      _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    }
    notifyListeners();
  }

  void toggleTheme(bool isDarkMode) async {
    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
    notifyListeners(); // Thông báo cho các widget lắng nghe để rebuild
  }
}