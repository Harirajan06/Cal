import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../models/food_item.dart';
import '../services/nutrient_ai_service.dart';
import 'package:provider/provider.dart';
import '../providers/food_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _analyzeImage();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            sliver: SliverToBoxAdapter(
              child: _isLoading ? _buildScanningState() : _buildResults(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
      bottomNavigationBar: !_isLoading && _foodLog != null
          ? _buildLogButton()
          : null,
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 350.0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(File(widget.imagePath), fit: BoxFit.cover),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Theme.of(
                            context,
                          ).scaffoldBackgroundColor.withOpacity(0.8),
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _isLoading ? 'SCANNING...' : 'ANALYSIS COMPLETE',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFCCFF00),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningState() {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
      highlightColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
      child: Column(
        children: List.generate(
          4,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Center(
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analysis Result',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 20),
        ..._foodLog!.items.asMap().entries.map(
          (entry) => _buildItemCard(entry.value, entry.key),
        ),
        const SizedBox(height: 10),
        Center(
          child: TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add, color: Color(0xFFCCFF00)),
            label: const Text(
              'Missing something?',
              style: TextStyle(color: Color(0xFFCCFF00)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard(FoodItem item, int index) {
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
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          item.foodName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          '${item.weightG.toInt()}g - ${item.calories.toInt()} kcal',
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined, color: Color(0xFFCCFF00)),
          onPressed: () => _showEditDialog(index),
        ),
      ),
    );
  }

  Widget _buildLogButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: ElevatedButton(
        onPressed: () {
          final foodProvider = Provider.of<FoodProvider>(
            context,
            listen: false,
          );
          final logWithImage = FoodLog(
            items: _foodLog!.items,
            timestamp: DateTime.now(),
            imagePath: widget.imagePath,
          );
          foodProvider.addLog(logWithImage);
          Navigator.popUntil(context, (route) => route.isFirst);
        },
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: const Color(0xFFCCFF00),
        ),
        child: const Text(
          'LOG MEAL',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  void _showEditDialog(int index) {
    final item = _foodLog!.items[index];
    final controller = TextEditingController(
      text: item.weightG.toInt().toString(),
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Edit Weight of ${item.foodName}',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            suffixText: 'g',
            suffixStyle: const TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              ),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFCCFF00)),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              final newWeight =
                  double.tryParse(controller.text) ?? item.weightG;
              final ratio = newWeight / item.weightG;
              setState(() {
                _foodLog!.items[index] = item.copyWith(
                  weightG: newWeight,
                  calories: item.calories * ratio,
                  protein: item.protein * ratio,
                  carbs: item.carbs * ratio,
                  fat: item.fat * ratio,
                );
              });
              Navigator.pop(context);
            },
            child: const Text(
              'SAVE',
              style: TextStyle(color: Color(0xFFCCFF00)),
            ),
          ),
        ],
      ),
    );
  }
}
