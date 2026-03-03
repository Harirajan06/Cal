import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/food_item.dart';

class NutrientAIService {
  // 1. Groq Configuration (Primary)
  final String _groqKey =
      "";
  final String _groqModel = "llama-3.2-11b-vision-preview";

  // 2. Gemini Configuration (Fallbacks)
  final List<String> _geminiKeys = [
    "",
    "",
    "",
  ];

  final String _systemPrompt = '''
    Identify food items in this image. Estimate weight in grams (g) and calculate Calories, Protein, Carbs, and Fat.
    Return ONLY a JSON object:
    {
      "items": [
        {"food_name": "string", "weight_g": number, "calories": number, "protein": number, "carbs": number, "fat": number}
      ],
      "total_calories": number
    }
  ''';

  Future<FoodLog> analyzeMeal(File image) async {
    final bytes = await image.readAsBytes();
    final base64Image = base64Encode(bytes);

    // TRY GROQ FIRST
    try {
      debugPrint('--- Attempting Groq (Primary) ---');
      return await _callGroq(base64Image);
    } catch (e) {
      debugPrint(
        'Groq failed or rate limited (429). Falling back to Gemini...',
      );
    }

    // TRY GEMINI KEY ROTATION
    for (String key in _geminiKeys) {
      try {
        debugPrint(
          '--- Attempting Gemini Fallback (Key: ${key.substring(0, 5)}) ---',
        );
        return await _callGemini(bytes, key);
      } catch (e) {
        if (e.toString().contains('429') || e.toString().contains('404')) {
          continue;
        }
        rethrow;
      }
    }

    throw Exception("All AI services exhausted. Try again later.");
  }

  Future<FoodLog> _callGroq(String base64Image) async {
    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $_groqKey',
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
    );

    if (response.statusCode == 200) {
      final content = jsonDecode(
        response.body,
      )['choices'][0]['message']['content'];
      return FoodLog.fromJson(
        jsonDecode(content)..['timestamp'] = DateTime.now().toIso8601String(),
      );
    } else {
      throw Exception('Groq error: ${response.statusCode}');
    }
  }

  Future<FoodLog> _callGemini(Uint8List bytes, String key) async {
    final model = GenerativeModel(
      model: 'gemini-2.5-flash-lite',
      apiKey: key,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.1,
      ),
    );

    final content = [
      Content.multi([TextPart(_systemPrompt), DataPart('image/jpeg', bytes)]),
    ];

    final response = await model.generateContent(content);
    if (response.text == null) throw Exception('Empty Gemini Response');

    return FoodLog.fromJson(
      jsonDecode(response.text!)
        ..['timestamp'] = DateTime.now().toIso8601String(),
    );
  }
}
