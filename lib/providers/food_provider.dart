import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/food_item.dart';
import '../services/nutrition_coach_service.dart';
import '../services/widget_service.dart';
import '../services/data_service.dart';

class FoodProvider with ChangeNotifier {
  final Box userBox = Hive.box('user_box');
  final Box mealBox = Hive.box('meal_box');
  final NutritionCoachService _coachService = NutritionCoachService();
  String? _smartAdvice;
  String? get smartAdvice => _smartAdvice;

  FoodProvider() {
    _updateWidget();
    updateSmartAdvice();
  }

  List<FoodLog>? _cachedAllMeals;
  List<FoodLog>? _cachedTodayMeals;
  double? _cachedTodayCalories;
  double? _cachedTodayProtein;
  double? _cachedTodayCarbs;
  double? _cachedTodayFat;

  void _invalidateCache() {
    _cachedAllMeals = null;
    _cachedTodayMeals = null;
    _cachedTodayCalories = null;
    _cachedTodayProtein = null;
    _cachedTodayCarbs = null;
    _cachedTodayFat = null;
  }

  Future<void> updateSmartAdvice() async {
    _smartAdvice = await _coachService.getSmartAdvice(
      consumedCalories: todayCalories,
      calorieGoal: calorieGoal,
      consumedProtein: todayProtein,
      proteinGoal: proteinGoal,
      consumedCarbs: todayCarbs,
      consumedFat: todayFat,
    );
    notifyListeners();
  }

  // Frequency tracking for Coaching Popups
  bool _hasCheckedLaunch = false;

  bool shouldShowCoachPopup() {
    if (_hasCheckedLaunch) return false;

    // Nutrient imbalance check (Prompt B logic)
    final totalMacroGrams = todayProtein + todayCarbs + todayFat;
    bool hasNutrientImbalance = false;
    if (totalMacroGrams > 50) {
      final carbPercent = todayCarbs / totalMacroGrams;
      final proteinPercent = todayProtein / totalMacroGrams;
      if (carbPercent > 0.60 && proteinPercent < 0.15) {
        hasNutrientImbalance = true;
      }
    }

    // Trigger if over calories OR has imbalance
    if (todayCalories <= calorieGoal && !hasNutrientImbalance) return false;

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

  bool get isPro => userBox.get('is_pro', defaultValue: false);
  Future<void> setPro(bool value) async {
    await userBox.put('is_pro', value);
    notifyListeners();
  }

  // Tracking Daily Usage
  int get dailyImageAnalysisCount {
    final String today = DateTime.now().toString().split(' ')[0];
    final String lastDate = userBox.get('last_image_date', defaultValue: '');
    if (lastDate != today) return 0;
    return userBox.get('image_analysis_count', defaultValue: 0);
  }

  int get dailyLiveAICount {
    final String today = DateTime.now().toString().split(' ')[0];
    final String lastDate = userBox.get('last_live_date', defaultValue: '');
    if (lastDate != today) return 0;
    return userBox.get('live_ai_count', defaultValue: 0);
  }

  Future<void> incrementImageAnalysis() async {
    final String today = DateTime.now().toString().split(' ')[0];
    int count = dailyImageAnalysisCount + 1;
    await userBox.put('image_analysis_count', count);
    await userBox.put('last_image_date', today);
    notifyListeners();
  }

  Future<void> incrementLiveAI() async {
    final String today = DateTime.now().toString().split(' ')[0];
    int count = dailyLiveAICount + 1;
    await userBox.put('live_ai_count', count);
    await userBox.put('last_live_date', today);
    notifyListeners();
  }

  bool canUseImageAnalysis() {
    if (isPro) return true;
    return dailyImageAnalysisCount < 3;
  }

  bool canUseLiveAI() {
    if (isPro) return true;
    return dailyLiveAICount < 3;
  }

  double get calorieGoal => userBox.get('calorie_goal', defaultValue: 2000.0);
  double get proteinGoal => userBox.get('protein_goal', defaultValue: 150.0);
  double get carbsGoal => userBox.get('carbs_goal', defaultValue: 250.0);
  double get fatGoal => userBox.get('fat_goal', defaultValue: 70.0);

  // Meal Calorie Targets (Approximate distribution)
  double get breakfastTarget => calorieGoal * 0.25;
  double get lunchTarget => calorieGoal * 0.35;
  double get dinnerTarget => calorieGoal * 0.30;
  double get snacksTarget => calorieGoal * 0.10;

  double get targetWeight => userBox.get('target_weight', defaultValue: 0.0);
  double get currentWeight => userBox.get('weight', defaultValue: 0.0);
  double get weeklyGoal => userBox.get('weekly_goal', defaultValue: 0.5);

  double get weeklyAverageCalories {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final lastWeekMeals = allMeals
        .where((log) => log.timestamp.isAfter(sevenDaysAgo))
        .toList();
    if (lastWeekMeals.isEmpty) return 0.0;

    // Group by day to get total per day then average
    Map<String, double> dailyTotals = {};
    for (var m in lastWeekMeals) {
      final d = m.timestamp.toString().split(' ')[0];
      dailyTotals[d] = (dailyTotals[d] ?? 0.0) + m.totalCalories;
    }
    double sum = dailyTotals.values.fold(0.0, (s, v) => s + v);
    return sum / 7;
  }

  List<double> get getWeeklyCalorieHistory {
    final now = DateTime.now();
    List<double> history = [];
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayStr = day.toString().split(' ')[0];
      double total = allMeals
          .where((m) => m.timestamp.toString().split(' ')[0] == dayStr)
          .fold(0.0, (sum, m) => sum + m.totalCalories);
      history.add(total);
    }
    return history;
  }

  String get goalType => userBox.get('goal', defaultValue: 'Lose');
  DateTime? get goalAchievementDate {
    final dateStr = userBox.get('achievement_date', defaultValue: '');
    if (dateStr.isEmpty) return null;
    return DateTime.parse(dateStr);
  }

  double get todayCalories {
    if (_cachedTodayCalories != null) return _cachedTodayCalories!;
    _cachedTodayCalories = todayMeals.fold<double>(
      0.0,
      (sum, log) => sum + log.totalCalories,
    );
    return _cachedTodayCalories!;
  }

  double get todayProtein {
    if (_cachedTodayProtein != null) return _cachedTodayProtein!;
    _cachedTodayProtein = todayMeals.fold<double>(
      0.0,
      (sum, log) => sum + log.totalProtein,
    );
    return _cachedTodayProtein!;
  }

  double get todayCarbs {
    if (_cachedTodayCarbs != null) return _cachedTodayCarbs!;
    _cachedTodayCarbs = todayMeals.fold<double>(
      0.0,
      (sum, log) => sum + log.totalCarbs,
    );
    return _cachedTodayCarbs!;
  }

  double get todayFat {
    if (_cachedTodayFat != null) return _cachedTodayFat!;
    _cachedTodayFat = todayMeals.fold<double>(
      0.0,
      (sum, log) => sum + log.totalFat,
    );
    return _cachedTodayFat!;
  }

  List<FoodLog> get todayMeals {
    if (_cachedTodayMeals != null) return _cachedTodayMeals!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _cachedTodayMeals = allMeals.where((log) {
      final logDate = DateTime(
        log.timestamp.year,
        log.timestamp.month,
        log.timestamp.day,
      );
      return logDate.isAtSameMomentAs(today);
    }).toList();
    return _cachedTodayMeals!;
  }

  int get todayWaterMl {
    final String today = DateTime.now().toString().split(' ')[0];
    return userBox.get('water_$today', defaultValue: 0);
  }

  int get waterGoalMl {
    final int stored = userBox.get('water_goal', defaultValue: 0);
    if (stored > 0) return stored;

    final double weight = currentWeight;
    if (weight <= 0) return 3000;

    double calc = weight * 35.0; // 35 ml per kg base
    if (goalType == 'Lose') {
      calc += 500; // Extra water for fat loss metabolism
    } else if (goalType == 'Gain') {
      calc += 300;
    }

    if (userActivityFactor > 1.2) {
      calc +=
          (userActivityFactor - 1.2) * 1500; // Extra water for activity levels
    }

    // Cap at reasonable limits
    if (calc > 6000) calc = 6000;

    return calc.toInt();
  }

  Future<void> addWater(int ml) async {
    final String today = DateTime.now().toString().split(' ')[0];
    final current = todayWaterMl;
    await userBox.put('water_$today', current + ml);
    notifyListeners();
    await _updateWidget();
  }

  List<FoodLog> get allMeals {
    if (_cachedAllMeals != null) return _cachedAllMeals!;
    final meals = mealBox.values.map((item) {
      return FoodLog.fromJson(Map<String, dynamic>.from(item));
    }).toList();
    // Sort by timestamp desc
    meals.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    _cachedAllMeals = meals;
    return _cachedAllMeals!;
  }

  List<bool> getWeeklyStreak() {
    final now = DateTime.now();
    // Get Sunday of the current week (Sunday is index 7 or 0)
    final daysToSubtract = now.weekday % 7;
    final firstDayOfStreak = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: daysToSubtract));

    final streak = List.generate(7, (index) => false);

    for (var i = 0; i < 7; i++) {
      final day = firstDayOfStreak.add(Duration(days: i));
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

  int get userAge => userBox.get('age', defaultValue: 25);
  String get userGender => userBox.get('gender', defaultValue: 'Male');
  double get userHeight => userBox.get('height', defaultValue: 170.0);
  double get userActivityFactor =>
      userBox.get('activity_factor', defaultValue: 1.2);

  Future<void> updateWeight(double newWeight) async {
    await userBox.put('weight', newWeight);

    // Recalculate goals with same profile but new weight
    setUserProfile(
      age: userAge,
      gender: userGender,
      weight: newWeight,
      height: userHeight,
      goal: goalType,
      targetWeight: targetWeight,
      weeklyGoal: weeklyGoal,
      activityFactor: userActivityFactor,
    );
  }

  Future<void> setUserProfile({
    required int age,
    required String gender,
    required double weight,
    required double height,
    required String goal,
    required double targetWeight,
    required double weeklyGoal,
    required double activityFactor,
  }) async {
    // Mifflin-St Jeor Formula
    double bmr;
    if (gender == 'Male') {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }

    double tdee = bmr * activityFactor;

    // Deficit/Surplus calculation
    double dailyAdjustment = weeklyGoal * 1000;
    double calorieGoal = tdee;

    if (goal == 'Lose') {
      calorieGoal = tdee - dailyAdjustment;
    } else if (goal == 'Gain') {
      calorieGoal = tdee + dailyAdjustment;
    } else {
      // Maintain
      calorieGoal = tdee;
    }

    // Minimum safety calories
    if (calorieGoal < 1200) calorieGoal = 1200;

    await userBox.put('goal', goal);
    await userBox.put('age', age);
    await userBox.put('gender', gender);
    await userBox.put('weight', weight);
    await userBox.put('height', height);
    await userBox.put('target_weight', targetWeight);
    await userBox.put('weekly_goal', weeklyGoal);
    await userBox.put('activity_factor', activityFactor);
    await userBox.put('calorie_goal', calorieGoal);

    // Protein Logic: Active users (gym/physical) get higher protein
    // Base is 30% of calories, but for high activity we ensure at least 1.8g/kg
    double proteinGrams = (calorieGoal * 0.3) / 4;
    if (activityFactor >= 1.55) {
      // Moderate/Very active - aim for roughly 2.0g per kg of weight
      proteinGrams = weight * 2.0;
      // Cap protein at 35% of total calories to avoid excessive balance shift
      double maxProtein = (calorieGoal * 0.35) / 4;
      if (proteinGrams > maxProtein) proteinGrams = maxProtein;
      // Ensure it's at least the 30% baseline
      if (proteinGrams < (calorieGoal * 0.3) / 4) {
        proteinGrams = (calorieGoal * 0.3) / 4;
      }
    }

    await userBox.put('protein_goal', proteinGrams);
    await userBox.put(
      'carbs_goal',
      (calorieGoal - (proteinGrams * 4) - (calorieGoal * 0.25)) / 4,
    );
    await userBox.put('fat_goal', (calorieGoal * 0.25) / 9);

    // Achievement Date
    if (weeklyGoal > 0) {
      final double weightDiff = (weight - targetWeight).abs();
      final double weeksToGoal = weightDiff / weeklyGoal;
      final int daysToGoal = (weeksToGoal * 7).round();
      final DateTime achievementDate = DateTime.now().add(
        Duration(days: daysToGoal),
      );
      await userBox.put('achievement_date', achievementDate.toIso8601String());
    }

    // Dynamic Water Goal Calculation
    double waterCalculation = weight * 35.0; // 35 ml per kg base
    if (goal == 'Lose') {
      waterCalculation += 500; // Extra water for fat loss metabolism
    } else if (goal == 'Gain') {
      waterCalculation += 300;
    }
    if (activityFactor > 1.2) {
      waterCalculation += (activityFactor - 1.2) * 1500; // Extra for activity
    }
    if (waterCalculation > 6000) waterCalculation = 6000;
    await userBox.put('water_goal', waterCalculation.toInt());

    await userBox.put('is_profile_setup', true);
    notifyListeners();
  }

  Future<void> _updateWidget() async {
    final bool isDarkMode = userBox.get('theme_mode') == 'dark';

    await WidgetService.updateStreakWidget(
      streakCount: currentStreakCount,
      weeklyStreak: getWeeklyStreak(),
      isDarkMode: isDarkMode,
    );
    await WidgetService.updateCalorieWidget(
      consumedCalories: todayCalories.toInt(),
      calorieGoal: calorieGoal.toInt(),
      waterIntake: todayWaterMl,
      isDarkMode: isDarkMode,
    );
  }

  Future<void> addLog(FoodLog log) async {
    await mealBox.add(log.toJson());
    if (log.waterMl > 0) {
      await addWater(log.waterMl);
    }
    _invalidateCache();
    _hasCheckedLaunch = false; // Reset to allow popup for new intake state
    await updateSmartAdvice();
    await _updateWidget();
    notifyListeners();
  }

  Future<void> updateLog(FoodLog oldLog, FoodLog newLog) async {
    final key = mealBox.keys.firstWhere((k) {
      final json = mealBox.get(k);
      final log = FoodLog.fromJson(Map<String, dynamic>.from(json));
      return log.timestamp.isAtSameMomentAs(oldLog.timestamp);
    }, orElse: () => null);

    if (key != null) {
      await mealBox.put(key, newLog.toJson());
      _invalidateCache();
      await updateSmartAdvice();
      await _updateWidget();
      notifyListeners();
    }
  }

  Future<void> deleteLog(FoodLog logToDelete) async {
    final key = mealBox.keys.firstWhere((k) {
      final json = mealBox.get(k);
      final log = FoodLog.fromJson(Map<String, dynamic>.from(json));
      return log.timestamp.isAtSameMomentAs(logToDelete.timestamp);
    }, orElse: () => null);

    if (key != null) {
      await mealBox.delete(key);
      _invalidateCache();
      await updateSmartAdvice();
      await _updateWidget();
      notifyListeners();
    }
  }

  Future<void> exportData() async {
    await DataService.exportData();
  }

  Future<bool> importData() async {
    final success = await DataService.importData();
    if (success) {
      _invalidateCache();
      await updateSmartAdvice();
      await _updateWidget();
      notifyListeners();
    }
    return success;
  }
}
