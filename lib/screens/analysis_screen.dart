import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import '../models/food_item.dart';
import '../services/nutrient_ai_service.dart';
import '../providers/food_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AnalysisScreen extends StatefulWidget {
  final String imagePath;

  const AnalysisScreen({super.key, required this.imagePath});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final NutrientAIService _aiService = NutrientAIService();
  FoodLog? _foodLog;
  bool _isLoading = true;
  String? _errorMessage;
  int _servingCount = 1;
  String _selectedMealType = 'Breakfast'; // Default
  late String _currentTime;
  final List<String> _loadingStatuses = [
    "Identifying ingredients...",
    "Estimating portion sizes...",
    "Calculating nutritional values...",
    "Analyzing macro balance...",
    "Finalizing report...",
  ];
  late final Stream<int> _statusStream;

  void _updateItem(int index, FoodItem newItem) {
    if (_foodLog == null) return;
    setState(() {
      final List<FoodItem> updatedItems = List.from(_foodLog!.items);
      updatedItems[index] = newItem;
      _foodLog = _foodLog!.copyWith(items: updatedItems);
    });
  }

  Future<void> _showEditItemDialog(int index) async {
    final item = _foodLog!.items[index];
    final nameController = TextEditingController(text: item.foodName);
    final qtyController = TextEditingController(text: item.quantity);
    final calController = TextEditingController(
      text: item.calories.toInt().toString(),
    );

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit ${item.foodName}',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Food Name'),
            ),
            TextField(
              controller: qtyController,
              decoration: const InputDecoration(
                labelText: 'Quantity (e.g. 2 items)',
              ),
            ),
            TextField(
              controller: calController,
              decoration: const InputDecoration(labelText: 'Calories'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _removeItem(index);
              Navigator.pop(context);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final updatedItem = item.copyWith(
                foodName: nameController.text,
                quantity: qtyController.text,
                calories: double.tryParse(calController.text) ?? item.calories,
              );
              _updateItem(index, updatedItem);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _removeItem(int index) {
    if (_foodLog == null) return;
    setState(() {
      final List<FoodItem> updatedItems = List.from(_foodLog!.items);
      updatedItems.removeAt(index);
      _foodLog = _foodLog!.copyWith(items: updatedItems);
    });
  }

  @override
  void initState() {
    super.initState();
    _currentTime = _formatTime(DateTime.now());
    _selectedMealType = _getInitialMealType(); // Set based on current hour
    _statusStream = Stream.periodic(
      const Duration(seconds: 2),
      (i) => (i + 1) % _loadingStatuses.length,
    );
    _analyzeImage();
  }

  String _getInitialMealType() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) return 'Breakfast';
    if (hour >= 11 && hour < 16) return 'Lunch';
    if (hour >= 18 && hour < 22) return 'Dinner';
    return 'Snacks';
  }

  String _formatTime(DateTime dateTime) {
    String hour = (dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12)
        .toString();
    String minute = dateTime.minute.toString().padLeft(2, '0');
    String period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Future<void> _analyzeImage() async {
    try {
      final log = await _aiService.analyzeMeal(File(widget.imagePath));
      if (mounted) {
        setState(() {
          _foodLog = log;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to analyze meal: $e";
          _isLoading = false;
        });
      }
    }
  }

  void _shareAnalysis() {
    if (_foodLog == null) return;

    final items = _foodLog!.items
        .map((i) => '${i.foodName} (${i.quantity})')
        .join(', ');
    final shareText =
        '''
🍽️ My Nutrition Analysis from Calx:
Items: $items
🔥 Total Calories: ${(_foodLog!.totalCalories * _servingCount).toInt()} kcal
🥚 Protein: ${(_foodLog!.totalProtein * _servingCount).toInt()}g
🍞 Carbs: ${(_foodLog!.totalCarbs * _servingCount).toInt()}g
🥑 Fats: ${(_foodLog!.totalFat * _servingCount).toInt()}g

Analyzed with Calx AI
''';

    Share.share(shareText);
  }

  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.refresh, color: Colors.blue),
              title: const Text('Analyze Again'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _analyzeImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Clear Analysis'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.60, // Image 60%
            child: Image.file(File(widget.imagePath), fit: BoxFit.cover),
          ),

          // AppBar Buttons
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCircleButton(
                  Icons.arrow_back,
                  () => Navigator.pop(context),
                ),
                Text(
                  'Nutrition',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    _buildCircleButton(Icons.ios_share, _shareAnalysis),
                    const SizedBox(width: 10),
                    _buildCircleButton(Icons.more_horiz, _showMoreMenu),
                  ],
                ),
              ],
            ),
          ),

          // Main Card
          Positioned.fill(
            top:
                MediaQuery.of(context).size.height *
                0.55, // Content Starts Lower
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                child: _isLoading ? _buildLoadingState() : _buildContent(),
              ),
            ),
          ),

          // Calorie Badge
          if (!_isLoading && _foodLog != null)
            Positioned(
              top:
                  MediaQuery.of(context).size.height *
                  0.51, // Badge overlaps 60/40 divide
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color ?? Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: SvgPicture.asset(
                        'assets/svg/streak_flame.svg',
                        colorFilter: ColorFilter.mode(
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                          BlendMode.srcIn,
                        ),
                        width: 20,
                        height: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Calories',
                          style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[400]
                                : Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${(_foodLog!.totalCalories * _servingCount).toInt()}',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: !_isLoading && _foodLog != null
          ? _buildBottomButtons()
          : null,
    );
  }

  Widget _buildCircleButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: SingleChildScrollView(
        key: const ValueKey('loading'),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPulsingAI(),
            const SizedBox(height: 24),
            StreamBuilder<int>(
              stream: _statusStream,
              initialData: 0,
              builder: (context, snapshot) {
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: Text(
                    _loadingStatuses[snapshot.data ?? 0],
                    key: ValueKey(snapshot.data),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            _buildShimmerSkeleton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPulsingAI() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.2),
      duration: const Duration(milliseconds: 1500),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome,
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        );
      },
      onEnd:
          () {}, // Handled by repeating tween in a real app, but for simplicity:
    );
  }

  Widget _buildShimmerSkeleton() {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[900]!
          : Colors.grey[200]!,
      highlightColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[800]!
          : Colors.white,
      child: Column(
        children: List.generate(
          2,
          (index) => Container(
            height: 80,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }

  void _cycleMealType() {
    final types = ['Breakfast', 'Lunch', 'Dinner', 'Snacks'];
    int currentIndex = types.indexOf(_selectedMealType);
    setState(() {
      _selectedMealType = types[(currentIndex + 1) % types.length];
    });
  }

  Widget _buildMealTypePill(String type) {
    return GestureDetector(
      onTap: _cycleMealType, // Cycle through types when tapped
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              type,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 14,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_errorMessage != null) {
      return Center(
        child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
      );
    }

    final itemNames = _foodLog!.items.map((i) => i.foodName).join(' with ');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(25, 40, 25, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.bookmark_border, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    _currentTime,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildMealTypePill(_selectedMealType),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  itemNames,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() {
                        if (_servingCount > 1) _servingCount--;
                      }),
                      child: const Icon(Icons.remove, size: 16),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Text(
                        '$_servingCount',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _servingCount++),
                      child: const Icon(Icons.add, size: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          Row(
            children: [
              _buildMacroSmallCard(
                'Protein',
                '${(_foodLog!.totalProtein * _servingCount).toInt()}g',
                Colors.redAccent,
                Icons.egg_outlined,
              ),
              const SizedBox(width: 12),
              _buildMacroSmallCard(
                'Carbs',
                '${(_foodLog!.totalCarbs * _servingCount).toInt()}g',
                Colors.orange,
                Icons.bakery_dining_outlined,
              ),
              const SizedBox(width: 12),
              _buildMacroSmallCard(
                'Fats',
                '${(_foodLog!.totalFat * _servingCount).toInt()}g',
                Colors.blue,
                Icons.opacity,
              ),
            ],
          ),
          const SizedBox(height: 30),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ingredients',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Text(
                  '+ Add more',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._foodLog!.items.asMap().entries.map(
            (entry) => _buildIngredientItem(entry.value, entry.key),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroSmallCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[900]
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 12),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientItem(FoodItem item, int index) {
    return GestureDetector(
      onTap: () => _showEditItemDialog(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[900]
              : Colors.grey[50], // Very light grey to match Image 1
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.foodName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '${item.calories.toInt()} cal',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Text(
                  item.quantity,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _removeItem(index),
                  child: Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: Colors.red[300],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.edit_outlined, size: 14, color: Colors.grey[400]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        10,
        20,
        MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _analyzeImage();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Fix Results'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[900]
                    : Colors.grey[100],
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                side: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                final foodProvider = Provider.of<FoodProvider>(
                  context,
                  listen: false,
                );
                // Save with selected meal type
                final finalLog = _foodLog!.copyWith(
                  mealType: _selectedMealType,
                  imagePath: widget.imagePath,
                );
                foodProvider.addLog(finalLog);
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 0,
              ),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}
