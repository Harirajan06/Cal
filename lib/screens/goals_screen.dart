import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/food_provider.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  late TextEditingController _weightController;
  late TextEditingController _targetWeightController;
  late String _goalType;
  late double _weeklyGoal;

  @override
  void initState() {
    super.initState();
    final foodProvider = Provider.of<FoodProvider>(context, listen: false);
    _weightController = TextEditingController(
      text: foodProvider.currentWeight.toStringAsFixed(1),
    );
    _targetWeightController = TextEditingController(
      text: foodProvider.targetWeight.toStringAsFixed(1),
    );
    _goalType = foodProvider.goalType;
    _weeklyGoal = foodProvider.weeklyGoal;
  }

  @override
  void dispose() {
    _weightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  void _saveGoals() {
    final foodProvider = Provider.of<FoodProvider>(context, listen: false);
    final weight =
        double.tryParse(_weightController.text) ?? foodProvider.currentWeight;
    final targetWeight =
        double.tryParse(_targetWeightController.text) ??
        foodProvider.targetWeight;

    foodProvider.setUserProfile(
      age: foodProvider.userAge,
      gender: foodProvider.userGender,
      weight: weight,
      height: foodProvider.userHeight,
      goal: _goalType,
      targetWeight: targetWeight,
      weeklyGoal: _weeklyGoal,
      activityFactor: foodProvider.userActivityFactor,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Goals updated successfully!'),
        backgroundColor: Color(0xFF673AB7),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFF673AB7);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Modify Goals',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Weight Plan'),
            const SizedBox(height: 12),
            _buildGoalSelector(orange),
            const SizedBox(height: 32),

            _buildSectionTitle('Current Weight (kg)'),
            const SizedBox(height: 12),
            _buildTextField(_weightController, 'Enter weight'),
            const SizedBox(height: 32),

            _buildSectionTitle('Target Weight (kg)'),
            const SizedBox(height: 12),
            _buildTextField(_targetWeightController, 'Enter target weight'),
            const SizedBox(height: 32),

            _buildSectionTitle('Weekly Pace (kg)'),
            const SizedBox(height: 12),
            _buildPaceSelector(orange),

            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saveGoals,
                style: ElevatedButton.styleFrom(
                  backgroundColor: orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'SAVE CHANGES',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Theme.of(context).cardTheme.color,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
    );
  }

  Widget _buildGoalSelector(Color orange) {
    return Row(
      children: [
        _goalOption('Lose', orange),
        const SizedBox(width: 12),
        _goalOption('Maintain', orange),
        const SizedBox(width: 12),
        _goalOption('Gain', orange),
      ],
    );
  }

  Widget _goalOption(String type, Color orange) {
    final isSelected = _goalType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _goalType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? orange : Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? null
                : Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: Center(
            child: Text(
              type,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaceSelector(Color orange) {
    final paces = [0.25, 0.5, 0.75, 1.0];
    return Row(children: paces.map((p) => _paceOption(p, orange)).toList());
  }

  Widget _paceOption(double pace, Color orange) {
    final isSelected = _weeklyGoal == pace;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _weeklyGoal = pace),
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? orange : Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? null
                : Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: Center(
            child: Text(
              '${pace}kg',
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
