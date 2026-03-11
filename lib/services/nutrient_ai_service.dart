import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/food_item.dart';

class NutrientAIService {
  // 1. Groq Configuration (Enabled)
  final List<String> _groqKeys = [
    dotenv.env['GROQ_API_KEY'] ?? '',
    dotenv.env['GROQ_API_KEY1'] ?? '',
    dotenv.env['GROQ_API_KEY2'] ?? '',
    dotenv.env['GROQ_API_KEY3'] ?? '',
    dotenv.env['GROQ_API_KEY4'] ?? '',
  ].where((k) => k.isNotEmpty).toList();

  final String _groqModel =
      "meta-llama/llama-4-scout-17b-16e-instruct"; // Updated to a more standard vision model if needed, but keeping user's choice if it was specific. Actually llama-4-scout-17b-16e-instruct is very niche/new, I will keep it but fix the name if it was wrong.
  // Wait, the user had "meta-llama/llama-4-scout-17b-16e-instruct". I'll stick to what they had unless it fails.

  int _currentKeyIndex = 0;

  // 2. Gemini Configuration (Fallback)
  final List<String> _geminiKeys = [
    dotenv.env['GEMINI_API_KEY'] ?? '',
    dotenv.env['GEMINI_API_KEY1'] ?? '',
    dotenv.env['GEMINI_API_KEY2'] ?? '',
  ].where((k) => k.isNotEmpty).toList();

  final String _systemPrompt = '''
    Analyze the image and identify each food item.
    For each item, provide:
    1. food_name (string)
    2. quantity (string, e.g., "2 items", "1 slice", "1 medium bowl") - ACCURATE COUNT IS CRITICAL.
    3. weight_g (number) - estimated total weight.
    4. calories (number)
    5. protein (number)
    6. carbs (number)
    7. fat (number)

    Return ONLY a JSON object:
    {
      "items": [
        {"food_name": "string", "quantity": "string", "weight_g": number, "calories": number, "protein": number, "carbs": number, "fat": number}
      ],
      "total_calories": number,
      "water_ml": number // Extract volume of water/liquid in ml if present (e.g. 1L -> 1000, 500ml -> 500, glass of water -> 250). Return 0 if no water.
    }
  ''';

  Future<FoodLog> analyzeMeal(File image) async {
    if (_groqKeys.isEmpty) {
      throw Exception('Groq API Keys missing: Please check your .env file');
    }

    final bytes = await image.readAsBytes();
    final base64Image = base64Encode(bytes);

    Exception? lastException;

    // Try each key in a round-robin fashion starting from the current index
    for (int i = 0; i < _groqKeys.length; i++) {
      final index = (_currentKeyIndex + i) % _groqKeys.length;
      final key = _groqKeys[index];

      try {
        debugPrint(
          '--- Attempting Groq (Key Index: $index, Model: $_groqModel) ---',
        );
        final result = await _callGroq(base64Image, key);

        // If successful, update the index for the next call (optional: stay on this key or move to next)
        _currentKeyIndex = index;
        return result.copyWith(imagePath: image.path);
      } catch (e) {
        debugPrint('Groq attempt with key $index failed: $e');
        lastException = e as Exception;
        // Continue to the next key
      }
    }

    // 2. Try Gemini Fallback if Groq fails
    debugPrint('Groq failed, trying Gemini fallback...');
    for (int i = 0; i < _geminiKeys.length; i++) {
      try {
        debugPrint('--- Attempting Gemini (Key Index: $i) ---');
        final result = await _callGemini(bytes, _geminiKeys[i]);
        return result.copyWith(imagePath: image.path);
      } catch (e) {
        debugPrint('Gemini attempt with key $i failed: $e');
        lastException = e as Exception;
      }
    }

    throw lastException ?? Exception('All AI services failed');
  }

  Future<FoodLog> _callGroq(String base64Image, String apiKey) async {
    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    final response = await http
        .post(
          url,
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            "model": _groqModel,
            "messages": [
              {
                "role": "user",
                "content": [
                  {"type": "text", "text": _systemPrompt},
                  {
                    "type": "image_url",
                    "image_url": {"url": "data:image/jpeg;base64,$base64Image"},
                  },
                ],
              },
            ],
            "response_format": {"type": "json_object"},
            "temperature": 0.1,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final content = jsonDecode(
        response.body,
      )['choices'][0]['message']['content'];
      return FoodLog.fromJson(
        jsonDecode(content)..['timestamp'] = DateTime.now().toIso8601String(),
      );
    } else {
      throw Exception('Groq error: ${response.statusCode} - ${response.body}');
    }
  }

  Future<FoodLog> _callGemini(Uint8List bytes, String key) async {
    final model = GenerativeModel(
      model: 'gemini-3.1-flash-lite-preview',
      apiKey: key,
    );

    final content = [
      Content.multi([TextPart(_systemPrompt), DataPart('image/jpeg', bytes)]),
    ];

    final response = await model.generateContent(
      content,
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );

    if (response.text == null) throw Exception('Empty Gemini Response');

    // Clean JSON string if enclosed in backticks
    String rawText = response.text!;
    if (rawText.contains('```json')) {
      rawText = rawText.split('```json')[1].split('```')[0].trim();
    } else if (rawText.contains('```')) {
      rawText = rawText.split('```')[1].split('```')[0].trim();
    }

    return FoodLog.fromJson(
      jsonDecode(rawText)..['timestamp'] = DateTime.now().toIso8601String(),
    );
  }

  Future<int> analyzeWaterBottle(File image) async {
    final String prompt = '''
      Analyze this image of a water bottle/glass.
      Extract the amount of water/liquid in milliliters (ml).
      If the text says "1L" or "1 Liter", return 1000.
      If the text says "500ml", return 500.
      If it's just a regular glass of water without text, estimate as 250.
      Return ONLY a JSON object: {"water_ml": number}
    ''';

    final bytes = await image.readAsBytes();

    // Just use Gemini directly for simplicity
    for (int i = 0; i < _geminiKeys.length; i++) {
      try {
        final model = GenerativeModel(
          model:
              'gemini-3.1-flash-lite-preview', // Or use standard gemini-1.5-flash
          apiKey: _geminiKeys[i],
        );
        final content = [
          Content.multi([TextPart(prompt), DataPart('image/jpeg', bytes)]),
        ];
        final response = await model.generateContent(
          content,
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
          ),
        );

        if (response.text != null) {
          String rawText = response.text!;
          if (rawText.contains('```json')) {
            rawText = rawText.split('```json')[1].split('```')[0].trim();
          } else if (rawText.contains('```')) {
            rawText = rawText.split('```')[1].split('```')[0].trim();
          }
          final decoded = jsonDecode(rawText);
          return (decoded['water_ml'] as num).toInt();
        }
      } catch (e) {
        debugPrint('Gemini water analysis failed: \$e');
      }
    }
    // Better default: standard glass of water if analysis fails
    return 250;
  }

  Future<FoodLog> analyzeFoodText(String foodDescription) async {
    final String prompt =
        '''
      You are an expert nutritionist. Analyze the following food description: "$foodDescription".
      Calculate the estimated nutritional values (calories, protein, carbs, fat, and weight in grams).
      $_systemPrompt
    ''';

    for (int i = 0; i < _geminiKeys.length; i++) {
      try {
        final model = GenerativeModel(
          model: 'gemini-3.1-flash-lite-preview',
          apiKey: _geminiKeys[i],
        );

        final content = [Content.text(prompt)];

        final response = await model.generateContent(
          content,
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
          ),
        );

        if (response.text != null) {
          String rawText = response.text!;
          if (rawText.contains('```json')) {
            rawText = rawText.split('```json')[1].split('```')[0].trim();
          } else if (rawText.contains('```')) {
            rawText = rawText.split('```')[1].split('```')[0].trim();
          }

          return FoodLog.fromJson(
            jsonDecode(rawText)
              ..['timestamp'] = DateTime.now().toIso8601String(),
          );
        }
      } catch (e) {
        debugPrint('Gemini text analysis failed with key \$i: \$e');
      }
    }

    throw Exception(
      'All AI text analysis attempts failed. Please try again or be more specific.',
    );
  }
}
