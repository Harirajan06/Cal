import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/food_item.dart';

class USDAService {
  final String apiKey = "Yyh0jK0VXXC8BTrBA2qhdLbQd9cOVNnA2ArIXfN5";
  final String baseUrl = "https://api.nal.usda.gov/fdc/v1/foods/search";

  Future<List<FoodItem>> searchFood(String query) async {
    final response = await http.get(
      Uri.parse("$baseUrl?api_key=$apiKey&query=$query&pageSize=10"),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List foods = data['foods'] ?? [];

      return foods.map((food) {
        final nutrients = food['foodNutrients'] as List;

        double findNutrient(String name) {
          final n = nutrients.firstWhere(
            (nut) => nut['nutrientName'].toString().toLowerCase().contains(
              name.toLowerCase(),
            ),
            orElse: () => null,
          );
          return (n?['value'] as num?)?.toDouble() ?? 0.0;
        }

        return FoodItem(
          foodName: food['description'],
          weightG: 100.0,
          calories: findNutrient('Energy'),
          protein: findNutrient('Protein'),
          carbs: findNutrient('Carbohydrate'),
          fat: findNutrient('Total lipid'),
        );
      }).toList();
    } else {
      throw Exception('Failed to load USDA data');
    }
  }
}
