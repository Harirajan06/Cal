import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NutritionCoachService {
  final String _groqKey = dotenv.env['GROQ_API_KEY'] ?? '';
  final String _model = "llama-3.1-8b-instant";

  Future<String?> getSmartAdvice({
    required double consumedCalories,
    required double calorieGoal,
    required double consumedProtein,
    required double proteinGoal,
    required double consumedCarbs,
    required double consumedFat,
  }) async {
    if (_groqKey.isEmpty) {
      return _getStaticAdvice(
        consumedCalories,
        calorieGoal,
        consumedProtein,
        proteinGoal,
        consumedCarbs,
        consumedFat,
      );
    }

    final totalMacros = consumedProtein + consumedCarbs + consumedFat;
    if (totalMacros == 0) return null;

    final prompt =
        """
      Act as a friendly Smart Nutritionist. Here is the intake:
      - Calories: $consumedCalories / $calorieGoal
      - Protein: ${consumedProtein}g
      - Carbs: ${consumedCarbs}g
      - Fat: ${consumedFat}g
      
      If Carbs are > 60% and Protein < 15% of the total macro grams, warn the user they are eating too many carbs and need more protein for muscle.
      Otherwise, give a short, encouraging tip.
      
      IMPORTANT: 
      - DO NOT show any math, percentages, or raw numbers in your advice.
      - DO NOT explain how you reached the conclusion.
      - Speak simply and human-to-human.
      - Max 25 words.
    """;

    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_groqKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": _model,
          "messages": [
            {"role": "user", "content": prompt},
          ],
          "temperature": 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      }
    } catch (e) {
      // Fallback to static
    }
    return _getStaticAdvice(
      consumedCalories,
      calorieGoal,
      consumedProtein,
      proteinGoal,
      consumedCarbs,
      consumedFat,
    );
  }

  String? _getStaticAdvice(
    double consumedCalories,
    double calorieGoal,
    double consumedProtein,
    double proteinGoal,
    double consumedCarbs,
    double consumedFat,
  ) {
    final double caloriesLeft = calorieGoal - consumedCalories;
    final double caloriesLeftPercent = (caloriesLeft / calorieGoal);

    if (consumedCalories > calorieGoal) {
      return "You’ve reached your calorie goal. If you choose to eat more, please keep logging every bite so we can stay honest with your progress!";
    }

    if (caloriesLeftPercent > 0 && caloriesLeftPercent < 0.15) {
      return "You’re almost at your limit for today! Stay strong and control those cravings.";
    }

    // Prompt B Logic fallback
    final totalMacroGrams = consumedProtein + consumedCarbs + consumedFat;
    if (totalMacroGrams > 50) {
      final carbPercent = consumedCarbs / totalMacroGrams;
      final proteinPercent = consumedProtein / totalMacroGrams;
      if (carbPercent > 0.60 && proteinPercent < 0.15) {
        return "You are filling your calories with too many carbs. To lose fat and keep muscle, try to eat more protein (like eggs or chicken) in your next meal!";
      }
    }

    return null;
  }
}
