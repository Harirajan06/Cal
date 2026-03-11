import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/food_provider.dart';
import 'dashboard_screen.dart';
import 'camera_screen.dart';
import 'manual_entry_screen.dart';
import 'progress_screen.dart';
import 'settings_screen.dart';

class MainLayout extends StatelessWidget {
  const MainLayout({super.key});

  final List<Widget> _screens = const [
    DashboardScreen(),
    ProgressScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final navProvider = Provider.of<NavigationProvider>(context);
    final foodProvider = Provider.of<FoodProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Current Screen
          _screens[navProvider.currentIndex],

          // Bottom solid background to block content behind floating nav
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).padding.bottom + 90,
            child: Container(color: Theme.of(context).scaffoldBackgroundColor),
          ),

          // Floating Navigation Bar
          Positioned(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: Row(
              children: [
                // 1. Navigation Pill
                Expanded(
                  child: Container(
                    height: 74,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF1A1A1A)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.black.withValues(alpha: 0.3)
                              : Colors.black.withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(
                          context,
                          index: 0,
                          icon: Icons.home_outlined,
                          activeIcon: Icons.home,
                          label: 'Home',
                          current: navProvider.currentIndex,
                          onTap: () => navProvider.setIndex(0),
                        ),
                        _buildNavItem(
                          context,
                          index: 1,
                          icon: Icons.bar_chart_outlined,
                          activeIcon: Icons.bar_chart,
                          label: 'Progress',
                          current: navProvider.currentIndex,
                          onTap: () => navProvider.setIndex(1),
                        ),
                        _buildNavItem(
                          context,
                          index: 2,
                          icon: Icons.settings_outlined,
                          activeIcon: Icons.settings,
                          label: 'Settings',
                          current: navProvider.currentIndex,
                          onTap: () => navProvider.setIndex(2),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // 2. Black Plus Button
                GestureDetector(
                  onTap: () {
                    if (foodProvider.todayCalories >=
                        foodProvider.calorieGoal) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Budget Exceeded! ⚠️'),
                          content: const Text(
                            'You have reached your daily calorie budget. To maintain your goals, logging more food is restricted for today. Focus on staying hydrated! 💧',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                      return;
                    }

                    // Show bottom sheet to choose entry method
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Theme.of(
                        context,
                      ).scaffoldBackgroundColor,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      builder: (context) => Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 24,
                          horizontal: 16,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 24),
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF673AB7,
                                  ).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Color(0xFF673AB7),
                                ),
                              ),
                              title: const Text(
                                'Take Photo',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: const Text(
                                'Use AI to log food instantly',
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const CameraScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit_note,
                                  color: Colors.orange,
                                ),
                              ),
                              title: const Text(
                                'Add Manually',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: const Text(
                                'Enter custom food and calories',
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ManualEntryScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color:
                          foodProvider.todayCalories >= foodProvider.calorieGoal
                          ? Colors.grey
                          : const Color(0xFF673AB7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 30),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int current,
    required VoidCallback onTap,
  }) {
    final bool isSelected = current == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color color = isSelected
        ? (isDark ? const Color(0xFFEEEEEE) : const Color(0xFF1A1A1A))
        : const Color(0xFF888888);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isSelected ? activeIcon : icon, color: color, size: 26),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
