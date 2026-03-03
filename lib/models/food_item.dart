class FoodLog {
  final List<FoodItem> items;
  final DateTime timestamp;
  final String? imagePath;

  FoodLog({required this.items, required this.timestamp, this.imagePath});

  double get totalCalories =>
      items.fold(0.0, (sum, item) => sum + item.calories);
  double get totalProtein => items.fold(0.0, (sum, item) => sum + item.protein);
  double get totalCarbs => items.fold(0.0, (sum, item) => sum + item.carbs);
  double get totalFat => items.fold(0.0, (sum, item) => sum + item.fat);

  factory FoodLog.fromJson(Map<String, dynamic> json) {
    return FoodLog(
      items:
          (json['items'] as List?)
              ?.map((i) => FoodItem.fromJson(Map<String, dynamic>.from(i)))
              .toList() ??
          [],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp']).toLocal()
          : DateTime.now(),
      imagePath: json['image_path'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((i) => i.toJson()).toList(),
      'total_calories': totalCalories,
      'timestamp': timestamp.toIso8601String(),
      'image_path': imagePath,
    };
  }
}

class FoodItem {
  final String foodName;
  final double weightG;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  FoodItem({
    required this.foodName,
    required this.weightG,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      foodName: json['food_name'] ?? json['name'] ?? 'Unknown',
      weightG: (json['weight_g'] as num?)?.toDouble() ?? 0.0,
      calories: (json['calories'] as num?)?.toDouble() ?? 0.0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0.0,
    );
  }

  FoodItem copyWith({
    String? foodName,
    double? weightG,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
  }) {
    return FoodItem(
      foodName: foodName ?? this.foodName,
      weightG: weightG ?? this.weightG,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'food_name': foodName,
      'weight_g': weightG,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }
}
