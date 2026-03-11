import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/food_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'goals_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final foodProvider = Provider.of<FoodProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GoalsScreen(),
                      ),
                    ),
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: Color(0xFF673AB7),
                    ),
                    label: const Text(
                      'Edit Goal',
                      style: TextStyle(
                        color: Color(0xFF673AB7),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              Row(
                children: [
                  Expanded(child: _buildWeightCard(context, foodProvider)),
                  const SizedBox(width: 15),
                  Expanded(child: _buildStreakCard(context, foodProvider)),
                ],
              ),

              const SizedBox(height: 25),
              _buildWeightProgressChart(context, foodProvider),

              const SizedBox(height: 25),
              _buildCoachStatus(context),

              const SizedBox(height: 25),
              _buildAverageCalories(context, foodProvider),

              const SizedBox(height: 110), // Space for floating nav bar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeightCard(BuildContext context, FoodProvider foodProvider) {
    final double currentWeight = foodProvider.currentWeight;
    final double targetWeight = foodProvider.targetWeight;
    // Simple progress toward goal
    double progress = 0.0;
    if (foodProvider.goalType == 'Lose') {
      // Progress = (Start - Current) / (Start - Target)
      // Since we don't have startWeight easily, let's just use current vs target
      progress = (targetWeight != 0) ? (currentWeight / targetWeight) : 0.0;
    } else {
      progress = (targetWeight != 0) ? (currentWeight / targetWeight) : 0.0;
    }

    return GestureDetector(
      onTap: () => _showWeightLogDialog(context, foodProvider),
      child: Container(
        height: 190, // Fixed height to match streak card
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Weight',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currentWeight.toStringAsFixed(1),
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 4),
                const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text(
                    'kg',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF222222)
                    : Colors.grey[200],
                color: const Color(0xFF673AB7),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Goal ${targetWeight.toStringAsFixed(1)} kg',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF673AB7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Log Weight',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.add, color: Colors.white, size: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWeightLogDialog(BuildContext context, FoodProvider provider) {
    final TextEditingController controller = TextEditingController(
      text: provider.currentWeight.toStringAsFixed(1),
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Weight'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Current Weight (kg)',
            suffixText: 'kg',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF673AB7),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final newWeight = double.tryParse(controller.text);
              if (newWeight != null) {
                provider.updateWeight(newWeight);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(BuildContext context, FoodProvider foodProvider) {
    final streakCount = foodProvider.currentStreakCount;
    final streakData = foodProvider.getWeeklyStreak();
    final days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    const primary = Color(0xFF673AB7);

    return Container(
      height: 190, // Fixed height to match weight card
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SvgPicture.asset(
                'assets/svg/streak_flame.svg',
                colorFilter: ColorFilter.mode(primary, BlendMode.srcIn),
                width: 36,
                height: 36,
              ),
              Positioned(
                bottom: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color ?? Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$streakCount',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Day Streak',
            style: TextStyle(
              color: primary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final isCompleted = index < streakData.length
                  ? streakData[index]
                  : false;
              return Column(
                children: [
                  Text(
                    days[index],
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? primary
                          : (Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[800]
                                : Colors.grey[200]),
                    ),
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 8)
                        : null,
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightProgressChart(
    BuildContext context,
    FoodProvider foodProvider,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primary = Color(0xFF673AB7);
    final calorieHistory = foodProvider.getWeeklyCalorieHistory;
    final goal = foodProvider.calorieGoal;
    final now = DateTime.now();

    // Day labels for last 7 days
    final dayLabels = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return names[d.weekday - 1];
    });

    // Max Y = max(goal * 1.25, max intake) rounded up nicely
    final maxVal = calorieHistory.fold(goal * 1.1, (m, v) => v > m ? v : m);
    final yMax = (maxVal / 200).ceil() * 200.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Calorie Intake',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              // Legend
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Intake',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? const Color(0xFF888888)
                          : Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 18,
                    height: 2,
                    color: isDark ? const Color(0xFF888888) : Colors.grey[400],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Goal',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? const Color(0xFF888888)
                          : Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '7-day overview · Goal ${goal.toInt()} kcal',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF888888) : Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: yMax,
                minY: 0,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: isDark
                        ? const Color(0xFF1A1A1A)
                        : Colors.black87,
                    tooltipRoundedRadius: 10,
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final kcal = rod.toY.toInt();
                      final diff = kcal - goal.toInt();
                      final diffText = diff >= 0
                          ? '+$diff over'
                          : '${diff.abs()} under';
                      return BarTooltipItem(
                        '${dayLabels[groupIndex]}\n',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        children: [
                          TextSpan(
                            text: '$kcal kcal\n',
                            style: TextStyle(
                              color: primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          TextSpan(
                            text: diffText,
                            style: TextStyle(
                              color: diff > 0
                                  ? const Color(0xFFFF5C8A)
                                  : const Color(0xFF00BFA5),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      interval: yMax / 4,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox();
                        return Text(
                          value >= 1000
                              ? '${(value / 1000).toStringAsFixed(1)}k'
                              : value.toInt().toString(),
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFF888888)
                                : Colors.grey[500],
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= dayLabels.length) {
                          return const SizedBox();
                        }
                        final isToday = idx == 6;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            dayLabels[idx],
                            style: TextStyle(
                              color: isToday
                                  ? primary
                                  : (isDark
                                        ? const Color(0xFF888888)
                                        : Colors.grey[500]),
                              fontSize: 10,
                              fontWeight: isToday
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: yMax / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: isDark ? const Color(0xFF222222) : Colors.grey[100]!,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                // Goal line
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: goal,
                      color: isDark
                          ? const Color(0xFF888888)
                          : Colors.grey[400]!,
                      strokeWidth: 1.5,
                      dashArray: [6, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(right: 4, bottom: 2),
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFF888888)
                              : Colors.grey[500],
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        labelResolver: (_) => 'Goal',
                      ),
                    ),
                  ],
                ),
                barGroups: calorieHistory.asMap().entries.map((e) {
                  final idx = e.key;
                  final kcal = e.value;
                  final isOver = kcal > goal;
                  final isToday = idx == 6;
                  final isEmpty = kcal == 0;

                  return BarChartGroupData(
                    x: idx,
                    barRods: [
                      BarChartRodData(
                        toY: isEmpty ? 0 : kcal,
                        width: 18,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                        gradient: isEmpty
                            ? null
                            : LinearGradient(
                                colors: isOver
                                    ? [
                                        const Color(0xFFFF5C8A),
                                        const Color(
                                          0xFFFF5C8A,
                                        ).withValues(alpha: 0.6),
                                      ]
                                    : isToday
                                    ? [primary, primary.withValues(alpha: 0.7)]
                                    : [
                                        primary.withValues(alpha: 0.7),
                                        primary.withValues(alpha: 0.35),
                                      ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                        color: isEmpty
                            ? (isDark
                                  ? const Color(0xFF222222)
                                  : Colors.grey[100])
                            : null,
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Summary row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildChartStat(
                context,
                label: 'Avg / day',
                value: '${foodProvider.weeklyAverageCalories.toInt()} kcal',
                isDark: isDark,
              ),
              Container(
                width: 1,
                height: 30,
                color: isDark ? const Color(0xFF222222) : Colors.grey[200],
              ),
              _buildChartStat(
                context,
                label: 'Goal',
                value: '${goal.toInt()} kcal',
                isDark: isDark,
                highlight: true,
              ),
              Container(
                width: 1,
                height: 30,
                color: isDark ? const Color(0xFF222222) : Colors.grey[200],
              ),
              _buildChartStat(
                context,
                label: 'Days logged',
                value: '${calorieHistory.where((v) => v > 0).length} / 7',
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartStat(
    BuildContext context, {
    required String label,
    required String value,
    required bool isDark,
    bool highlight = false,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: highlight
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? const Color(0xFF888888) : Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCoachStatus(BuildContext context) {
    final foodProvider = Provider.of<FoodProvider>(context);
    final advice =
        foodProvider.smartAdvice ??
        'Calx is analyzing your data to give you personalized coaching.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF21152F)
            : const Color(0xFFF3E5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        advice,
        style: const TextStyle(
          color: Color(0xFF7B1FA2),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildAverageCalories(
    BuildContext context,
    FoodProvider foodProvider,
  ) {
    final avg = foodProvider.weeklyAverageCalories;
    final goal = foodProvider.calorieGoal;
    final double percent = (goal != 0) ? (avg / goal) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Daily Average Calories',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${avg.toInt()}',
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 6),
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'cal',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${(percent * 100).toInt()}% of goal',
                style: TextStyle(
                  color: (percent > 1.0) ? Colors.red : Colors.green,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          '${goal.toInt()}',
          style: const TextStyle(color: Colors.grey, fontSize: 11),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent.clamp(0.0, 1.0),
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF222222)
                : Colors.grey[200],
            color: const Color(0xFF673AB7),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}
