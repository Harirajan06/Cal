import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/food_provider.dart';
import '../widgets/app_logo.dart';
import 'main_layout.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Stats to collect
  String _gender = 'Male';
  int _age = 25;
  double _weight = 70.0;
  double _targetWeight = 65.0;
  double _weeklyGoal = 0.5;
  double _height = 170.0;
  String _goal = 'Lose';
  double _activityFactor = 1.2;

  final List<Map<String, dynamic>> _activities = [
    {
      'label': 'Sedentary',
      'value': 1.2,
      'desc': 'Desk job, very little daily movement',
    },
    {
      'label': 'Lightly Active',
      'value': 1.375,
      'desc': 'Daily walking or 1-2 gym sessions',
    },
    {
      'label': 'Moderately Active',
      'value': 1.55,
      'desc': 'Active job or 3-5 gym/sports sessions',
    },
    {
      'label': 'Very Active',
      'value': 1.725,
      'desc': 'Daily intense gym or physical labor',
    },
    {
      'label': 'Extra Active',
      'value': 1.9,
      'desc': 'Professional athlete or extreme labor',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const AppLogo(size: 60),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: List.generate(
                  9,
                  (index) => Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: _currentPage >= index
                            ? const Color(0xFF673AB7)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildIntroPage(),
                  _buildGenderPage(),
                  _buildAgePage(),
                  _buildWeightPage(),
                  _buildHeightPage(),
                  _buildTargetWeightPage(),
                  _buildGoalPage(),
                  _buildActivityPage(),
                  _buildWeeklyGoalPage(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(30.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      child: const Text(
                        'Back',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < 8) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _finishOnboarding();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A1A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 42,
                        vertical: 16,
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _currentPage == 8 ? 'GET STARTED' : 'Next',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _finishOnboarding() async {
    final provider = Provider.of<FoodProvider>(context, listen: false);
    await provider.setUserProfile(
      age: _age,
      gender: _gender,
      weight: _weight,
      height: _height,
      goal: _goal,
      targetWeight: _targetWeight,
      weeklyGoal: _weeklyGoal,
      activityFactor: _activityFactor,
    );

    // Navigate to main app
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainLayout()),
      );
    }
  }

  Widget _buildIntroPage() {
    return _pageTemplate(
      'Welcome to Calx',
      'Your personal AI-powered calorie and nutrition guide.',
      Center(
        child: Column(
          children: [
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF673AB7).withValues(alpha: 0.2),
                  width: 8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600&q=80',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              '"Health is not just about what you\'re eating. It\'s also about what you\'re thinking and saying."',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Let\'s build your perfect plan Together.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF673AB7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderPage() {
    return _pageTemplate(
      'Choose Gender',
      'Calx uses this to personalize your metabolic calculations.',
      Column(
        children: [
          _optionTile(
            'Male',
            _gender == 'Male',
            () => setState(() => _gender = 'Male'),
          ),
          const SizedBox(height: 15),
          _optionTile(
            'Female',
            _gender == 'Female',
            () => setState(() => _gender = 'Female'),
          ),
        ],
      ),
    );
  }

  Widget _buildAgePage() {
    return _pageTemplate(
      'Your Age',
      'Helps Calx determine your baseline energy needs.',
      _numberPicker(
        _age.toDouble(),
        1.0,
        120.0,
        (v) => setState(() => _age = v.toInt()),
        'years',
      ),
    );
  }

  Widget _buildTargetWeightPage() {
    return _pageTemplate(
      'Target Weight',
      "Tell Calx where you want to be.",
      _numberPicker(
        _targetWeight,
        20,
        300,
        (v) => setState(() => _targetWeight = v),
        'kg',
      ),
    );
  }

  Widget _buildWeeklyGoalPage() {
    return _pageTemplate(
      'What is your weekly goal?',
      'How fast do you want to reach your goal?',
      Column(
        children: [
          _optionTile(
            '${_goal == 'Gain' ? 'Gain' : 'Lose'} 0.10 kg / week',
            _weeklyGoal == 0.1,
            () => setState(() => _weeklyGoal = 0.1),
            subtitle: _goal == 'Gain'
                ? 'Slow muscle gain'
                : 'Consistent progress',
          ),
          const SizedBox(height: 15),
          _optionTile(
            '${_goal == 'Gain' ? 'Gain' : 'Lose'} 0.25 kg / week',
            _weeklyGoal == 0.25,
            () => setState(() => _weeklyGoal = 0.25),
            subtitle: 'Recommended for sustainable progress',
          ),
          const SizedBox(height: 15),
          _optionTile(
            '${_goal == 'Gain' ? 'Gain' : 'Lose'} 0.50 kg / week',
            _weeklyGoal == 0.5,
            () => setState(() => _weeklyGoal = 0.5),
            subtitle: 'Standard ${_goal == 'Gain' ? 'gain' : 'loss'} goal',
          ),
        ],
      ),
    );
  }

  Widget _buildWeightPage() {
    return _pageTemplate(
      'Current Weight',
      "Your starting point for the Calx journey.",
      _numberPicker(_weight, 20, 300, (v) => setState(() => _weight = v), 'kg'),
    );
  }

  Widget _buildHeightPage() {
    return _pageTemplate(
      'How tall are you?',
      "Essential for accurate BMI and BMR tracking.",
      _numberPicker(
        _height,
        100,
        250,
        (v) => setState(() => _height = v),
        'cm',
      ),
    );
  }

  Widget _buildGoalPage() {
    return _pageTemplate(
      'Daily Objective',
      'Choose how Calx should guide your nutrition.',
      Column(
        children: [
          _optionTile(
            'Lose',
            _goal == 'Lose',
            () => setState(() => _goal = 'Lose'),
          ),
          const SizedBox(height: 15),
          _optionTile(
            'Maintain',
            _goal == 'Maintain',
            () => setState(() => _goal = 'Maintain'),
          ),
          const SizedBox(height: 15),
          _optionTile(
            'Gain',
            _goal == 'Gain',
            () => setState(() => _goal = 'Gain'),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityPage() {
    return _pageTemplate(
      'Workout & Lifestyle',
      'Impacts daily energy expenditure (TDEE).',
      Column(
        children: _activities.expand((act) {
          return [
            _optionTile(
              act['label'],
              _activityFactor == act['value'],
              () => setState(() => _activityFactor = act['value']),
              subtitle: act['desc'],
            ),
            const SizedBox(height: 12),
          ];
        }).toList()..removeLast(),
      ),
    );
  }

  Widget _pageTemplate(String title, String subtitle, Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 40),
                child,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _optionTile(
    String label,
    bool isSelected,
    VoidCallback onTap, {
    String? subtitle,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF673AB7).withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF673AB7) : Colors.grey[200]!,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF673AB7).withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                color: isSelected
                    ? Theme.of(context).colorScheme.onSurface
                    : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected
                      ? Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7)
                      : Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _numberPicker(
    double value,
    double min,
    double max,
    Function(double) onChanged,
    String unit,
  ) {
    return Column(
      children: [
        SizedBox(
          height: 250,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Selection highlight
              Container(
                height: 60,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF673AB7).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.symmetric(
                    horizontal: BorderSide(
                      color: const Color(0xFF673AB7).withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                ),
              ),
              ListWheelScrollView.useDelegate(
                itemExtent: 60,
                diameterRatio: 1.5,
                perspective: 0.005,
                physics: const FixedExtentScrollPhysics(),
                controller: FixedExtentScrollController(
                  initialItem: (value - min).toInt(),
                ),
                onSelectedItemChanged: (index) {
                  onChanged(min + index);
                },
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: (max - min).toInt() + 1,
                  builder: (context, index) {
                    final val = (min + index).toInt();
                    final isSelected = val == value.toInt();
                    return Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$val',
                            style: GoogleFonts.poppins(
                              fontSize: isSelected ? 36 : 24,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w400,
                              color: isSelected
                                  ? const Color(0xFF673AB7)
                                  : Colors.grey.withValues(alpha: 0.5),
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 8),
                            Text(
                              unit,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF673AB7),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Scroll to select your $unit',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
