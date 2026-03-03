import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/food_provider.dart';
import '../widgets/app_logo.dart';

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
  double _height = 170.0;
  String _goal = 'Lose';
  double _activityFactor = 1.2;

  final List<Map<String, dynamic>> _activities = [
    {'label': 'Sedentary', 'value': 1.2, 'desc': 'Office job, little movement'},
    {
      'label': 'Lightly Active',
      'value': 1.375,
      'desc': 'Exercise 1-3x per week',
    },
    {
      'label': 'Moderately Active',
      'value': 1.55,
      'desc': 'Exercise 3-5x per week',
    },
    {
      'label': 'Very Active',
      'value': 1.725,
      'desc': 'Hard exercise/physical job',
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
                  6,
                  (index) => Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: _currentPage >= index
                            ? const Color(0xFFCCFF00)
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.1),
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
                  _buildGenderPage(),
                  _buildAgePage(),
                  _buildWeightPage(),
                  _buildHeightPage(),
                  _buildGoalPage(),
                  _buildActivityPage(),
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
                      if (_currentPage < 5) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _finishOnboarding();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                    ),
                    child: Text(_currentPage == 5 ? 'GET STARTED' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _finishOnboarding() {
    final provider = Provider.of<FoodProvider>(context, listen: false);
    provider.setUserProfile(
      age: _age,
      gender: _gender,
      weight: _weight,
      height: _height,
      goal: _goal,
      activityFactor: _activityFactor,
    );
  }

  Widget _buildGenderPage() {
    return _pageTemplate(
      'What is your gender?',
      'Base your selection on your biological profile.',
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
      'How old are you?',
      'Impacts metabolic rate calculation.',
      _numberPicker(
        _age.toDouble(),
        1.0,
        120.0,
        (v) => setState(() => _age = v.toInt()),
        'years',
      ),
    );
  }

  Widget _buildWeightPage() {
    return _pageTemplate(
      'What is your current weight?',
      "Consistency is key.",
      _numberPicker(_weight, 20, 300, (v) => setState(() => _weight = v), 'kg'),
    );
  }

  Widget _buildHeightPage() {
    return _pageTemplate(
      'What is your height?',
      "Impacts BMR.",
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
      'What is your daily goal?',
      'Impacts calorie targets.',
      Column(
        children: [
          _optionTile(
            'Lose',
            _goal == 'Lose',
            () => setState(() => _goal = 'Lose'),
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
      'How active are you?',
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
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
              ? const Color(0xFFCCFF00).withOpacity(0.1)
              : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFCCFF00) : Colors.transparent,
            width: 2,
          ),
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
                      ? Theme.of(context).colorScheme.onSurface.withOpacity(0.7)
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
        Text(
          '${value.toInt()} $unit',
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Color(0xFFCCFF00),
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFFCCFF00),
            thumbColor: Colors.white,
            overlayColor: const Color(0xFFCCFF00).withOpacity(0.2),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: (v) => onChanged(v),
          ),
        ),
      ],
    );
  }
}
