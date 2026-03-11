import 'package:home_widget/home_widget.dart';

class WidgetService {
  static const String androidWidgetName = 'StreakWidgetProvider';
  static const String androidCalorieWidgetName = 'CalorieWidgetProvider';

  static Future<void> updateStreakWidget({
    required int streakCount,
    required List<bool> weeklyStreak,
    required bool isDarkMode,
  }) async {
    // Convert List<bool> to String "1010111"
    final String streakInfo = weeklyStreak.map((e) => e ? '1' : '0').join();

    await HomeWidget.saveWidgetData<int>('streak_count', streakCount);
    await HomeWidget.saveWidgetData<String>('streak_info', streakInfo);
    await HomeWidget.saveWidgetData<bool>('is_dark_mode', isDarkMode);

    await HomeWidget.updateWidget(
      androidName: androidWidgetName,
      // iOS name would go here if implemented
    );
  }

  static Future<void> updateCalorieWidget({
    required int consumedCalories,
    required int calorieGoal,
    required int waterIntake,
    required bool isDarkMode,
  }) async {
    await HomeWidget.saveWidgetData<int>('consumed_calories', consumedCalories);
    await HomeWidget.saveWidgetData<int>('calorie_goal', calorieGoal);
    await HomeWidget.saveWidgetData<int>('water_intake', waterIntake);
    await HomeWidget.saveWidgetData<bool>('is_dark_mode', isDarkMode);

    await HomeWidget.updateWidget(androidName: androidCalorieWidgetName);
  }

  static Future<void> refreshWidgetsTheme(bool isDarkMode) async {
    await HomeWidget.saveWidgetData<bool>('is_dark_mode', isDarkMode);
    await HomeWidget.updateWidget(androidName: androidWidgetName);
    await HomeWidget.updateWidget(androidName: androidCalorieWidgetName);
  }
}
