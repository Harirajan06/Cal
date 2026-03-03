class NutritionCoachService {
  String? getCoachMessage({
    required double consumedCalories,
    required double calorieGoal,
    required double consumedProtein,
    required double proteinGoal,
    required double consumedCarbs,
    required double consumedFat,
  }) {
    final double caloriesLeft = calorieGoal - consumedCalories;
    final double caloriesLeftPercent = (caloriesLeft / calorieGoal);
    final int currentHour = DateTime.now().hour;

    // Rule 4: Accountability Reminder (Over Limit)
    if (consumedCalories > calorieGoal) {
      return "You’ve reached your calorie goal. If you choose to eat more, please keep logging every bite so we can stay honest with your progress!";
    }

    // Rule 1: Calorie Warning (Near Limit)
    if (caloriesLeftPercent > 0 && caloriesLeftPercent < 0.15) {
      return "You’re almost at your limit for today! Stay strong and control those cravings. Remember to snap a photo before you eat anything else!";
    }

    // Rule 3: Macro Imbalance (Low Protein - Time Sensitive)
    final double proteinPercentOfGoal = (consumedProtein / proteinGoal);
    if (currentHour >= 16 && proteinPercentOfGoal < 0.30) {
      return "Your protein intake is low today. Consider a high-protein snack like Greek yogurt or a protein shake to hit your goal!";
    }

    // Rule 2: Macro Imbalance (High Carbs/Fats)
    // We calculate current macro distribution percentages
    final double totalGrams = consumedProtein + consumedCarbs + consumedFat;
    if (totalGrams > 0) {
      final double proteinDist = consumedProtein / totalGrams;
      final double carbsDist = consumedCarbs / totalGrams;
      final double fatDist = consumedFat / totalGrams;

      if (proteinDist < 0.20) {
        if (carbsDist > 0.70) {
          return "You’ve mostly had Carbs today. To stay balanced and feel full longer, try adding some lean protein to your next meal!";
        }
        if (fatDist > 0.70) {
          return "You’ve mostly had Fats today. To stay balanced and feel full longer, try adding some lean protein to your next meal!";
        }
      }
    }

    return null; // No message at this time
  }
}
