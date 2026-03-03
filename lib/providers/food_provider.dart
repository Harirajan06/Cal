import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/food_item.dart';
import '../services/nutrition_coach_service.dart';

class FoodProvider with ChangeNotifier {
  final Box userBox = Hive.box('user_box');
  final Box mealBox = Hive.box('meal_box');
  final NutritionCoachService _coachService = NutritionCoachService();

  String? get coachMessage => _coachService.getCoachMessage(
    consumedCalories: todayCalories,
    calorieGoal: dailyCalorieGoal,
    consumedProtein: todayProtein,
    proteinGoal: proteinGoal,
    consumedCarbs: todayCarbs,
    consumedFat: todayFat,
  );

  // Frequency tracking for Coaching Popups
  bool _hasCheckedLaunch = false;

  bool shouldShowCoachPopup() {
    if (_hasCheckedLaunch) return false;
    if (todayCalories <= dailyCalorieGoal) return false;

    // Daily count limit of 3
    final String today = DateTime.now().toString().split(' ')[0];
    final String lastPopupDate = userBox.get(
      'last_popup_date',
      defaultValue: '',
    );
    int count = userBox.get('popup_count', defaultValue: 0);

    if (lastPopupDate != today) {
      count = 0;
    }

    if (count >= 3) return false;

    return true;
  }

  void markCoachPopupShown() {
    _hasCheckedLaunch = true;
    final String today = DateTime.now().toString().split(' ')[0];
    int count = userBox.get('popup_count', defaultValue: 0);
    final String lastPopupDate = userBox.get(
      'last_popup_date',
      defaultValue: '',
    );

    if (lastPopupDate == today) {
      count++;
    } else {
      count = 1;
    }

    userBox.put('popup_count', count);
    userBox.put('last_popup_date', today);
    notifyListeners();
  }

  double get dailyCalorieGoal =>
      userBox.get('calorie_goal', defaultValue: 2000.0);
  double get proteinGoal => userBox.get('protein_goal', defaultValue: 150.0);
  double get carbsGoal => userBox.get('carbs_goal', defaultValue: 250.0);
  double get fatGoal => userBox.get('fat_goal', defaultValue: 70.0);

  double get todayCalories =>
      todayMeals.fold(0, (sum, log) => sum + log.totalCalories);
  double get todayProtein =>
      todayMeals.fold(0, (sum, log) => sum + log.totalProtein);
  double get todayCarbs =>
      todayMeals.fold(0, (sum, log) => sum + log.totalCarbs);
  double get todayFat => todayMeals.fold(0, (sum, log) => sum + log.totalFat);

  List<FoodLog> get todayMeals {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return allMeals.where((log) {
      final logDate = DateTime(
        log.timestamp.year,
        log.timestamp.month,
        log.timestamp.day,
      );
      return logDate.isAtSameMomentAs(today);
    }).toList();
  }

  List<FoodLog> get allMeals {
    final meals = mealBox.values.map((item) {
      return FoodLog.fromJson(Map<String, dynamic>.from(item));
    }).toList();
    // Sort by timestamp desc
    meals.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return meals;
  }

  List<bool> getWeeklyStreak() {
    final now = DateTime.now();
    final firstDayOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final streak = List.generate(7, (index) => false);

    for (var i = 0; i < 7; i++) {
      final day = DateTime(
        firstDayOfWeek.year,
        firstDayOfWeek.month,
        firstDayOfWeek.day + i,
      );
      streak[i] = allMeals.any(
        (meal) =>
            meal.timestamp.year == day.year &&
            meal.timestamp.month == day.month &&
            meal.timestamp.day == day.day,
      );
    }
    return streak;
  }

  int get currentStreakCount {
    int count = 0;
    final now = DateTime.now();
    DateTime checkDate = DateTime(now.year, now.month, now.day);

    while (true) {
      bool hasLog = allMeals.any(
        (meal) =>
            meal.timestamp.year == checkDate.year &&
            meal.timestamp.month == checkDate.month &&
            meal.timestamp.day == checkDate.day,
      );

      if (hasLog) {
        count++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return count;
  }

  void setUserProfile({
    required int age,
    required String gender,
    required double weight,
    required double height,
    required String goal,
    required double activityFactor,
  }) async {
    double bmr;
    if (gender == 'Male') {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }

    double tdee = bmr * activityFactor;
    double calorieGoal = goal == 'Lose' ? tdee - 500 : tdee + 500;

    await userBox.put('calorie_goal', calorieGoal);
    await userBox.put('protein_goal', (calorieGoal * 0.3) / 4);
    await userBox.put('carbs_goal', (calorieGoal * 0.4) / 4);
    await userBox.put('fat_goal', (calorieGoal * 0.3) / 9);
    await userBox.put('is_profile_setup', true);

    notifyListeners();
  }

  Future<void> addLog(FoodLog log) async {
    await mealBox.add(log.toJson());
    notifyListeners();
  }
}
