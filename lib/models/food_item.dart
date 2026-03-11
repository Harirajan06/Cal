class FoodLog {
  final List<FoodItem> items;
  final DateTime timestamp;
  final String? imagePath;
  final String mealType; // New field: Breakfast, Lunch, Dinner, Snacks
  final int waterMl;

  FoodLog({
    required this.items,
    required this.timestamp,
    this.imagePath,
    this.mealType = 'Other',
    this.waterMl = 0,
  });

  FoodLog copyWith({
    List<FoodItem>? items,
    DateTime? timestamp,
    String? imagePath,
    String? mealType,
    int? waterMl,
  }) {
    return FoodLog(
      items: items ?? this.items,
      timestamp: timestamp ?? this.timestamp,
      imagePath: imagePath ?? this.imagePath,
      mealType: mealType ?? this.mealType,
      waterMl: waterMl ?? this.waterMl,
    );
  }

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
      mealType: json['meal_type'] ?? 'Other',
      waterMl: (json['water_ml'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((i) => i.toJson()).toList(),
      'total_calories': totalCalories,
      'timestamp': timestamp.toIso8601String(),
      'image_path': imagePath,
      'meal_type': mealType,
      'water_ml': waterMl,
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
  final String quantity; // Added field

  FoodItem({
    required this.foodName,
    required this.weightG,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.quantity = "1 unit", // Default value
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      foodName: json['food_name'] ?? json['name'] ?? 'Unknown',
      weightG: (json['weight_g'] as num?)?.toDouble() ?? 0.0,
      calories: (json['calories'] as num?)?.toDouble() ?? 0.0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0.0,
      quantity: json['quantity']?.toString() ?? "1 unit",
    );
  }

  FoodItem copyWith({
    String? foodName,
    double? weightG,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    String? quantity,
  }) {
    return FoodItem(
      foodName: foodName ?? this.foodName,
      weightG: weightG ?? this.weightG,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      quantity: quantity ?? this.quantity,
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
      'quantity': quantity,
    };
  }
}
