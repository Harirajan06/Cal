import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

class DataService {
  /// Exports all app data to a JSON file and opens the share dialog.
  static Future<void> exportData() async {
    try {
      final userBox = Hive.box('user_box');
      final mealBox = Hive.box('meal_box');

      final userData = <String, dynamic>{};
      for (var key in userBox.keys) {
        userData[key.toString()] = userBox.get(key);
      }

      final mealData = mealBox.values.toList();

      final fullData = {
        'user_data': userData,
        'meal_data': mealData,
        'exported_at': DateTime.now().toIso8601String(),
        'app': 'Calx',
        'version': 1,
      };

      final jsonString = jsonEncode(fullData);
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/calx_backup_$timestamp.json');
      await file.writeAsString(jsonString);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: 'Calx Data Backup',
        text:
            'Backup of my Calx app data from ${DateTime.now().toString().split('.')[0]}',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Imports app data from a JSON file selected by the user.
  /// Returns [true] if import was successful, [false] otherwise.
  static Future<bool> importData() async {
    try {
      // Simplify permissions: Just request basic storage for older Androids
      if (Platform.isAndroid) {
        await Permission.storage.request();
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result != null) {
        final platformFile = result.files.single;
        String jsonString;

        if (platformFile.bytes != null) {
          jsonString = utf8.decode(platformFile.bytes!);
        } else if (platformFile.path != null) {
          final file = File(platformFile.path!);
          jsonString = await file.readAsString();
        } else {
          return false;
        }

        final data = jsonDecode(jsonString) as Map<String, dynamic>;
        debugPrint("Importing data with keys: ${data.keys}");
        return await _processImport(data);
      }
      return false;
    } catch (e) {
      debugPrint("Import Error: $e");
      return false;
    }
  }

  static Future<bool> _processImport(Map<String, dynamic> data) async {
    try {
      if (data.containsKey('user_data') && data.containsKey('meal_data')) {
        final userBox = Hive.box('user_box');
        final mealBox = Hive.box('meal_box');

        // Clear existing data safely
        await userBox.clear();
        await mealBox.clear();

        // Restore user data
        final userData = data['user_data'] as Map<String, dynamic>;
        for (var entry in userData.entries) {
          // Attempt to restore numeric types if they were encoded as strings
          var value = entry.value;
          await userBox.put(entry.key, value);
        }

        // Restore meal data
        final mealData = data['meal_data'] as List;
        for (var meal in mealData) {
          if (meal is Map) {
            await mealBox.add(Map<String, dynamic>.from(meal));
          } else {
            await mealBox.add(meal);
          }
        }

        debugPrint(
          "Imported ${userData.length} user settings and ${mealData.length} meals.",
        );
        return true;
      }
      debugPrint("Invalid backup format: Missing user_data or meal_data");
      return false;
    } catch (e) {
      debugPrint("Process Import Error: $e");
      return false;
    }
  }
}
