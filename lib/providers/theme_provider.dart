import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/widget_service.dart';

class ThemeProvider with ChangeNotifier {
  final Box _userBox = Hive.box('user_box');

  ThemeMode get themeMode {
    final String? theme = _userBox.get('theme_mode');
    if (theme == 'light') return ThemeMode.light;
    if (theme == 'dark') return ThemeMode.dark;
    return ThemeMode.light; // Default to Light as requested
  }

  bool get isDarkMode => themeMode == ThemeMode.dark;

  void setThemeMode(ThemeMode mode) async {
    String themeStr = 'light';
    if (mode == ThemeMode.dark) themeStr = 'dark';
    if (mode == ThemeMode.system) themeStr = 'system';

    await _userBox.put('theme_mode', themeStr);

    // Sync with widgets
    await WidgetService.refreshWidgetsTheme(themeStr == 'dark');

    notifyListeners();
  }

  void toggleTheme() {
    if (themeMode == ThemeMode.dark) {
      setThemeMode(ThemeMode.light);
    } else {
      setThemeMode(ThemeMode.dark);
    }
  }
}
