import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'goals_screen.dart';
import '../providers/food_provider.dart';
import '../models/food_item.dart';
import 'pro_screen.dart'; // Added
import '../widgets/app_logo.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final foodProvider = Provider.of<FoodProvider>(context);
    final dayMeals = foodProvider.allMeals.where((log) {
      return log.timestamp.year == _selectedDate.year &&
          log.timestamp.month == _selectedDate.month &&
          log.timestamp.day == _selectedDate.day;
    }).toList();

    final consumed = dayMeals.fold(0.0, (sum, log) => sum + log.totalCalories);
    final consumedProtein = dayMeals.fold(
      0.0,
      (sum, log) => sum + log.totalProtein,
    );
    final consumedCarbs = dayMeals.fold(
      0.0,
      (sum, log) => sum + log.totalCarbs,
    );
    final consumedFat = dayMeals.fold(0.0, (sum, log) => sum + log.totalFat);

    final goal = foodProvider.calorieGoal;
    final left = (goal - consumed).clamp(0.0, goal);

    // Optimization: Group meals by day for the weekly date picker at once
    final now = DateTime.now();
    final int daysSinceSunday = now.weekday == 7 ? 0 : now.weekday;
    final DateTime startOfWeek = now.subtract(Duration(days: daysSinceSunday));

    final Map<String, List<FoodLog>> weekMealsMap = {};
    for (var log in foodProvider.allMeals) {
      if (log.timestamp.isAfter(
            startOfWeek.subtract(const Duration(days: 1)),
          ) &&
          log.timestamp.isBefore(startOfWeek.add(const Duration(days: 8)))) {
        final key =
            "${log.timestamp.year}-${log.timestamp.month}-${log.timestamp.day}";
        weekMealsMap.putIfAbsent(key, () => []).add(log);
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(25, 4, 20, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),

              const SizedBox(height: 6),
              _buildDatePicker(startOfWeek, weekMealsMap),
              const SizedBox(height: 20),
              _buildCalorieAndMacroSection(
                consumed,
                goal,
                left,
                consumedProtein,
                consumedCarbs,
                consumedFat,
                foodProvider,
                dayMeals,
              ),
              const SizedBox(height: 8),
              _buildRecentlyUploaded(foodProvider),
              const SizedBox(height: 110), // Space for floating nav bar
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  HEADER
  // ─────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final foodProvider = Provider.of<FoodProvider>(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 0, bottom: 10),
              child: const AppLogo(size: 26, isHeader: true),
            ),
            const SizedBox(width: 8),
            Text(
              'Calx',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF673AB7),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.workspace_premium,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      foodProvider.isPro ? 'PRO' : 'GO PRO',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  DATE PICKER
  // ─────────────────────────────────────────────────────────────
  Color _getDayColor(DateTime date, List<FoodLog> dayMeals) {
    if (dayMeals.isEmpty) return Colors.transparent;

    final protein = dayMeals.fold(0.0, (sum, log) => sum + log.totalProtein);
    final carbs = dayMeals.fold(0.0, (sum, log) => sum + log.totalCarbs);
    final fat = dayMeals.fold(0.0, (sum, log) => sum + log.totalFat);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (protein >= carbs && protein >= fat) {
      return isDark ? const Color(0xFF00796B) : const Color(0xFF673AB7);
    } else if (carbs >= protein && carbs >= fat) {
      return isDark ? const Color(0xFFF57F17) : const Color(0xFFFFAB40);
    } else {
      return isDark ? const Color(0xFFC2185B) : const Color(0xFFFF80AB);
    }
  }

  Widget _buildDatePicker(
    DateTime startOfWeek,
    Map<String, List<FoodLog>> weekMealsMap,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
            width: 1,
          ),
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (index) {
          final date = startOfWeek.add(Duration(days: index));
          final isSelected =
              date.day == _selectedDate.day &&
              date.month == _selectedDate.month;

          final key = "${date.year}-${date.month}-${date.day}";
          final dayMeals = weekMealsMap[key] ?? [];
          final dayColor = _getDayColor(date, dayMeals);
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final highlightColor = isDark
              ? Colors.white
              : const Color(0xFF673AB7);

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedDate = date),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Weekday Name at Top
                    Text(
                      _getWeekdayShort(date.weekday),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isSelected ? highlightColor : Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 10),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: dayColor != Colors.transparent
                            ? dayColor
                            : (isSelected
                                  ? (isDark
                                        ? Colors.white.withValues(alpha: 0.1)
                                        : const Color(
                                            0xFF673AB7,
                                          ).withValues(alpha: 0.1))
                                  : (isDark ? Colors.grey[900] : Colors.white)),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? highlightColor
                              : (isDark
                                    ? Colors.grey[800]!
                                    : Colors.grey[100]!),
                          width: isSelected ? 2.5 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: highlightColor.withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: Center(
                        child: Text(
                          date.day.toString(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: isSelected
                                ? (dayColor != Colors.transparent
                                      ? Colors.white
                                      : highlightColor)
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  String _getWeekdayShort(int day) {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[day % 7];
  }

  // ─────────────────────────────────────────────────────────────
  //  CALORIE + MACRO SECTION
  // ─────────────────────────────────────────────────────────────
  Widget _buildCalorieAndMacroSection(
    double consumed,
    double goal,
    double left,
    double protein,
    double carbs,
    double fat,
    FoodProvider foodProvider,
    List<FoodLog> dayMeals,
  ) {
    final progress = (consumed / goal).clamp(0.0, 1.0);

    return SizedBox(
      height: 380,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Circular arc + food image (left, partially clipped) ──
          Positioned(
            left: -160,
            top: -10,
            child: SizedBox(
              width: 300,
              height: 300,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Custom arc painter (270° sweep, starts from 135°)
                  CustomPaint(
                    size: const Size(300, 300),
                    painter: _ArcProgressPainter(
                      progress: progress,
                      isDark: Theme.of(context).brightness == Brightness.dark,
                    ),
                  ),
                  // Food image circle
                  Container(
                    width: 238,
                    height: 238,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF673AB7).withValues(alpha: 0.3),
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 40,
                          offset: const Offset(0, 16),
                        ),
                      ],
                      image: DecorationImage(
                        image:
                            dayMeals.isNotEmpty &&
                                dayMeals.first.imagePath != null
                            ? FileImage(File(dayMeals.first.imagePath!))
                                  as ImageProvider
                            : const NetworkImage(
                                'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600&q=80',
                              ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Stats column (right) ──
          Positioned(
            left: 130,
            right: 0,
            top: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔥 Consumed row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF2A1515)
                            : const Color(0xFFFFF0F0),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.redAccent.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: SvgPicture.asset(
                        'assets/svg/streak_flame.svg',
                        colorFilter: const ColorFilter.mode(
                          Colors.redAccent,
                          BlendMode.srcIn,
                        ),
                        width: 20,
                        height: 20,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '${consumed.toInt()}',
                                style: GoogleFonts.poppins(
                                  fontSize: 46,
                                  fontWeight: FontWeight.w800,
                                  height: 0.95,
                                  color: consumed > goal
                                      ? Colors.redAccent
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Kcal',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? const Color(0xFF888888)
                                        : Colors.grey[800],
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  'Consumed',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Left stat
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          consumed > goal
                              ? '! ${(consumed - goal).toInt()}'
                              : '${left.toInt()}',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: consumed > goal
                                ? Colors.redAccent
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          consumed > goal ? 'Over Budget' : 'Left',
                          style: TextStyle(
                            color: consumed > goal
                                ? Colors.redAccent
                                : Colors.grey[500],
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Macro pills — staircase
                _buildMacroPill(
                  label: 'Proteins',
                  value:
                      '${protein.toInt()}/${foodProvider.proteinGoal.toInt()}',
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF00796B) // Teal matching date picker
                      : const Color(0xFF673AB7),
                  bgColor: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF21152F)
                      : const Color(0xFFF3E5F5),
                  icon: '🍗',
                  leftPad: 48,
                ),
                const SizedBox(height: 12),
                _buildMacroPill(
                  label: 'Carbs',
                  value: '${carbs.toInt()}/${foodProvider.carbsGoal.toInt()}',
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFF57F17) // Amber matching date picker
                      : const Color(0xFFFFAB40),
                  bgColor: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF2A220D)
                      : const Color(0xFFFFF4D6),
                  icon: '🍞',
                  leftPad: 32,
                ),
                const SizedBox(height: 12),
                _buildMacroPill(
                  label: 'Fats',
                  value: '${fat.toInt()}/${foodProvider.fatGoal.toInt()}',
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFC2185B) // Pink matching date picker
                      : const Color(0xFFFF80AB),
                  bgColor: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF2A0D1A)
                      : const Color(0xFFFFE4EF),
                  icon: '🥑',
                  leftPad: 16,
                ),
              ],
            ),
          ),

          // ── Budget & Mini Meal Cards (bottom) ──
          Positioned(
            bottom: 25,
            left: 10,
            right: 0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GoalsScreen(),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${goal.toInt()}',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Kcal',
                            style: TextStyle(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? const Color(0xFF888888)
                                  : Colors.grey[700],
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Budget',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: const _WaterLevelMonitorWidget(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroPill({
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
    required String icon,
    required double leftPad,
  }) {
    final parts = value.split('/');
    final current = double.tryParse(parts[0]) ?? 0;
    final total = double.tryParse(parts[1]) ?? 1;
    final progress = (current / total).clamp(0.0, 1.0);

    return Padding(
      padding: EdgeInsets.only(left: leftPad),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? color.withValues(alpha: 0.85)
                  : bgColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.5),
                    Theme.of(context).cardColor,
                  ],
                  stops: [progress, progress],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF222222)
                      : Colors.white,
                  width: 1.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: parts[0],
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextSpan(
                          text: '/${parts[1]}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  MEAL SECTION  (matches screenshot — food photos in cards)
  // ─────────────────────────────────────────────────────────────

  Widget _buildRecentlyUploaded(FoodProvider foodProvider) {
    final meals = foodProvider.allMeals;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recently uploaded',
          style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        if (meals.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.no_food_outlined,
                  size: 30,
                  color: Colors.grey.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 8),
                Text(
                  'No food items yet',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        else
          ...meals.take(3).map((meal) => _buildRecentMealCard(meal)),
      ],
    );
  }

  Widget _buildRecentMealCard(FoodLog meal) {
    return GestureDetector(
      onTap: () => _showEditMealSheet(meal),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: meal.imagePath != null
                  ? Image.file(
                      File(meal.imagePath!),
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[900]
                          : Colors.grey[100],
                      child: const Center(child: AppLogo(size: 30)),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          meal.items.map((i) => i.foodName).join(', '),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTimeShort(meal.timestamp),
                        style: TextStyle(color: Colors.grey[400], fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        color: Colors.redAccent,
                        size: 15,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${meal.totalCalories.toInt()} Calories',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _miniMacro('🥩', '${meal.totalProtein.toInt()}g'),
                      const SizedBox(width: 10),
                      _miniMacro('🌾', '${meal.totalCarbs.toInt()}g'),
                      const SizedBox(width: 10),
                      _miniMacro('🧈', '${meal.totalFat.toInt()}g'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditMealSheet(FoodLog meal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditMealSheet(meal: meal),
    );
  }

  Widget _miniMacro(String emoji, String value) {
    return Row(
      children: [
        FittedBox(child: Text(emoji, style: const TextStyle(fontSize: 13))),
        const SizedBox(width: 3),
        Text(
          value,
          style: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  String _formatTimeShort(DateTime dt) {
    int hour = dt.hour;
    final period = hour >= 12 ? 'pm' : 'am';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute$period';
  }
}

// ─────────────────────────────────────────────────────────────
//  Custom Arc Painter — 270° sweep starting from bottom-left
//  matches the screenshot's green progress ring
// ─────────────────────────────────────────────────────────────
class _ArcProgressPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  const _ArcProgressPainter({required this.progress, this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    const startAngle = -90.0 * math.pi / 180.0;
    const sweepTotal = 270.0 * math.pi / 180.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 16) / 2;

    // Track (background arc)
    final trackPaint = Paint()
      ..color = isDark
          ? Colors.grey[800]!.withValues(alpha: 0.3)
          : Colors.grey[300]!.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    // Progress arc
    final progressPaint = Paint()
      ..color = const Color(0xFF673AB7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal,
      false,
      trackPaint,
    );

    // Show at least a tiny bit if progress is 0 but track exists
    final effectiveProgress = math.max(progress, 0.005);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal * effectiveProgress,
      false,
      progressPaint,
    );

    // Purple glow dot at the progress tip (dark mode only)
    if (isDark) {
      final dotAngle = startAngle + sweepTotal * effectiveProgress;
      final dotCenter = Offset(
        center.dx + radius * math.cos(dotAngle),
        center.dy + radius * math.sin(dotAngle),
      );

      // Glow effect removed for flat design
      final glowPaint = Paint()
        ..color = const Color(0xFF673AB7).withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(dotCenter, 8, glowPaint);

      // Solid dot
      final dotPaint = Paint()..color = const Color(0xFF673AB7);
      canvas.drawCircle(dotCenter, 6, dotPaint);

      // Inner white dot
      final innerDotPaint = Paint()..color = Colors.white;
      canvas.drawCircle(dotCenter, 3, innerDotPaint);
    }
  }

  @override
  bool shouldRepaint(_ArcProgressPainter old) =>
      old.progress != progress || old.isDark != isDark;
}

// ─────────────────────────────────────────────────────────────
//  Water Level Monitor Widget
// ─────────────────────────────────────────────────────────────
class _WaterLevelMonitorWidget extends StatefulWidget {
  const _WaterLevelMonitorWidget();

  @override
  State<_WaterLevelMonitorWidget> createState() =>
      _WaterLevelMonitorWidgetState();
}

class _WaterLevelMonitorWidgetState extends State<_WaterLevelMonitorWidget> {
  @override
  Widget build(BuildContext context) {
    final foodProvider = Provider.of<FoodProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final currentWater = foodProvider.todayWaterMl;
    final goalWater = foodProvider.waterGoalMl;
    final progress = (currentWater / goalWater).clamp(0.0, 1.0);

    final color = isDark ? const Color(0xFF00E5FF) : const Color(0xFF2196F3);
    final bgColor = isDark ? const Color(0xFF0F1B29) : const Color(0xFFE3F2FD);

    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isDark ? color.withValues(alpha: 0.85) : bgColor,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Text('🥤', style: TextStyle(fontSize: 14)),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.5),
                  Theme.of(context).cardColor,
                ],
                stops: [progress, progress],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark ? const Color(0xFF222222) : Colors.white,
                width: 1.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Water',
                        style: TextStyle(
                          color: isDark
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(width: 10),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '$currentWater',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            TextSpan(
                              text: '/$goalWater',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () {
            // Add 250ml of water
            Provider.of<FoodProvider>(context, listen: false).addWater(250);
          },
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 18),
          ),
        ),
      ],
    );
  }
}

class EditMealSheet extends StatefulWidget {
  final FoodLog meal;
  const EditMealSheet({super.key, required this.meal});

  @override
  State<EditMealSheet> createState() => _EditMealSheetState();
}

class _EditMealSheetState extends State<EditMealSheet> {
  late double currentCalories;
  late double initialCalories;
  late double initialProtein;
  late double initialCarbs;
  late double initialFat;

  @override
  void initState() {
    super.initState();
    initialCalories = widget.meal.totalCalories;
    initialProtein = widget.meal.totalProtein;
    initialCarbs = widget.meal.totalCarbs;
    initialFat = widget.meal.totalFat;
    currentCalories = initialCalories;
  }

  void _adjustCalories(double delta) {
    setState(() {
      currentCalories = (currentCalories + delta).clamp(0, 10000);
    });
  }

  @override
  Widget build(BuildContext context) {
    final factor = initialCalories > 0
        ? currentCalories / initialCalories
        : 1.0;
    final protein = initialProtein * factor;
    final carbs = initialCarbs * factor;
    final fat = initialFat * factor;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.meal.items.map((e) => e.foodName).join(', '),
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: widget.meal.imagePath != null
                ? Image.file(
                    File(widget.meal.imagePath!),
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Container(
                    height: 180,
                    width: double.infinity,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[900]
                        : Colors.grey[100],
                    child: const Center(child: AppLogo(size: 60)),
                  ),
          ),
          const SizedBox(height: 30),
          // Calorie editor
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _circularButton(
                  icon: Icons.remove,
                  onPressed: () => _adjustCalories(-50),
                ),
                const SizedBox(width: 30),
                Column(
                  children: [
                    Text(
                      '${currentCalories.toInt()}',
                      style: GoogleFonts.poppins(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF673AB7),
                      ),
                    ),
                    Text(
                      'Kcal',
                      style: GoogleFonts.poppins(
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 30),
                _circularButton(
                  icon: Icons.add,
                  onPressed: () => _adjustCalories(50),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          // Macro row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _macroMetric('🥩', 'Protein', protein),
              _macroMetric('🍞', 'Carbs', carbs),
              _macroMetric('🥑', 'Fats', fat),
            ],
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF673AB7),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {
                final newLog = widget.meal.copyWith(
                  items: widget.meal.items
                      .map(
                        (item) => item.copyWith(
                          calories: item.calories * factor,
                          protein: item.protein * factor,
                          carbs: item.carbs * factor,
                          fat: item.fat * factor,
                          weightG: item.weightG * factor,
                        ),
                      )
                      .toList(),
                );
                Provider.of<FoodProvider>(
                  context,
                  listen: false,
                ).updateLog(widget.meal, newLog);
                Navigator.pop(context);
              },
              child: Text(
                'Update Log',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Log?'),
                  content: const Text(
                    'Are you sure you want to remove this food item?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Provider.of<FoodProvider>(
                          context,
                          listen: false,
                        ).deleteLog(widget.meal);
                        Navigator.pop(context); // close dialog
                        Navigator.pop(context); // close sheet
                      },
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
            child: Text(
              'Delete Log',
              style: GoogleFonts.poppins(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _circularButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF673AB7).withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF673AB7), size: 24),
      ),
    );
  }

  Widget _macroMetric(String icon, String label, double value) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          '${value.toInt()}g',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
