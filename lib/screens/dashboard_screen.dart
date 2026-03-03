import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import '../providers/food_provider.dart';
import '../models/food_item.dart';
import '../widgets/app_logo.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();

    // AI Coach Popup Check
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkCoachPopup();
    });
  }

  void _checkCoachPopup() {
    final foodProvider = Provider.of<FoodProvider>(context, listen: false);

    // Only show popup for critical accountability (Over Limit)
    // AND limit to 3 times a day + once per app entry
    if (foodProvider.shouldShowCoachPopup()) {
      foodProvider.markCoachPopupShown();
      showDialog(
        context: context,
        builder: (context) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            backgroundColor: const Color(0xFF111111),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: Color(0xFFCCFF00), width: 1),
            ),
            title: Row(
              children: [
                const Icon(Icons.tips_and_updates, color: Color(0xFFCCFF00)),
                const SizedBox(width: 10),
                Text(
                  'Coach Insight',
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              foodProvider.coachMessage ??
                  "You've reached your calorie goal for today. Stay mindful of your next choices!",
              style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFCCFF00),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                child: Text(
                  'GOT IT',
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final foodProvider = Provider.of<FoodProvider>(context);

    final consumed = foodProvider.todayCalories;
    final goal = foodProvider.dailyCalorieGoal;
    final left = (goal - consumed).clamp(0.0, goal);
    final percent = (consumed / goal).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 15),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cal',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const AppLogo(size: 35),
                ],
              ),
              const SizedBox(height: 15),

              // Weekly Streak
              _buildWeeklyStreak(foodProvider),

              const SizedBox(height: 60),

              // Main Circle Ring
              Center(
                child: CircularPercentIndicator(
                  radius: 100.0,
                  lineWidth: 18.0,
                  percent: percent,
                  circularStrokeCap: CircularStrokeCap.round,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.05),
                  progressColor: const Color(0xFFCCFF00),
                  animation: true,
                  center: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${left.toInt()}',
                        style: GoogleFonts.poppins(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'CALORIES LEFT',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Horizontal Macros
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMacroBar(
                    'PROTEIN',
                    foodProvider.todayProtein,
                    foodProvider.proteinGoal,
                    Colors.orange,
                  ),
                  _buildMacroBar(
                    'CARBS',
                    foodProvider.todayCarbs,
                    foodProvider.carbsGoal,
                    Colors.blue,
                  ),
                  _buildMacroBar(
                    'FATS',
                    foodProvider.todayFat,
                    foodProvider.fatGoal,
                    Colors.red,
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Daily History Label
              Text(
                'Daily Timeline',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(child: _buildDailyTimeline(foodProvider.todayMeals)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyStreak(FoodProvider foodProvider) {
    final List<String> days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final List<bool> streakData = foodProvider.getWeeklyStreak();
    final int streakCount = foodProvider.currentStreakCount;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Weekly Streak',
              style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                const Icon(
                  Icons.local_fire_department,
                  color: Color(0xFFCCFF00),
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  '$streakCount Days',
                  style: const TextStyle(
                    color: Color(0xFFCCFF00),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (index) {
            bool isCompleted = streakData[index];
            return Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? const Color(0xFFCCFF00)
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                border: Border.all(
                  color: isCompleted
                      ? const Color(0xFFCCFF00)
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.1),
                ),
              ),
              child: Center(
                child: Text(
                  days[index],
                  style: TextStyle(
                    color: isCompleted ? Colors.black : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildMacroBar(
    String label,
    double consumed,
    double goal,
    Color color,
  ) {
    final double percent = (consumed / goal).clamp(0.0, 1.0);
    return Column(
      children: [
        LinearPercentIndicator(
          animation: true,
          width: 80.0,
          lineHeight: 6.0,
          percent: percent,
          progressColor: color,
          backgroundColor: Theme.of(
            context,
          ).colorScheme.onSurface.withOpacity(0.05),
          barRadius: const Radius.circular(10),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        Text(
          '${consumed.toInt()}g',
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyTimeline(List<FoodLog> meals) {
    if (meals.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: const Center(
          child: Text(
            'No meals logged yet today.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: meals.length,
      itemBuilder: (context, index) {
        final meal = meals[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: meal.imagePath != null
                  ? Image.file(
                      File(meal.imagePath!),
                      height: 40,
                      width: 40,
                      fit: BoxFit.cover,
                    )
                  : Container(height: 40, width: 40, color: Colors.grey[900]),
            ),
            title: Text(
              meal.items.map((i) => i.foodName).join(', '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              _formatTime(meal.timestamp),
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
            trailing: Text(
              '${meal.totalCalories.toInt()} kcal',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFFCCFF00),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dt) {
    int hour = dt.hour;
    String period = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    String minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
}
