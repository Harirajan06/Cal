import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

class GeminiLiveService {
  final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  late final GenerativeModel _model;

  GeminiLiveService() {
    _model = GenerativeModel(
      model: 'gemini-3.1-flash-lite-preview',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );
    _initTts();
  }

  void _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
  }

  Future<bool> initSpeech() async {
    bool available = await _speechToText.initialize();
    return available;
  }

  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }

  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
  }

  Future<String> askGemini(File image, String userQuestion) async {
    try {
      final bytes = await image.readAsBytes();
      final content = [
        Content.multi([
          DataPart('image/jpeg', bytes),
          TextPart('''
            You are Calx Nutrition AI. You have two modes: "talk" (chatting) and "log" (adding food to diary).
            
            1. If the user asks a general question about the food (e.g. "is this healthy?"), use "type": "talk".
            2. If the user explicitly asks to "add", "log", "save", or "record" food (e.g. "add this to my breakfast" or "log two eggs"), use "type": "log".
            
            For "log" type, analyze the image and the user's voice command to extract the food items.
            
            Return JSON only:
            {
              "type": "talk" | "log",
              "text": "Your spoken response to the user",
              "food_log": {
                "items": [
                  {"food_name": "string", "quantity": "string", "weight_g": number, "calories": number, "protein": number, "carbs": number, "fat": number}
                ]
              } (Required ONLY if type is "log")
            }
            
            User said: "$userQuestion"
            Keep the "text" part short and natural for a conversation.
            '''),
        ]),
      ];

      final response = await _model.generateContent(content);
      return response.text ??
          '{"type": "talk", "text": "I didn\'t catch that."}';
    } catch (e) {
      return '{"type": "talk", "text": "Sorry, AI connection failed $e"}';
    }
  }

  Future<bool> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.microphone,
      Permission.camera,
    ].request();
    return statuses[Permission.microphone]!.isGranted &&
        statuses[Permission.camera]!.isGranted;
  }
}
