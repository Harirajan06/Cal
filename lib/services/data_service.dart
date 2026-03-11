import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';

class DataService {
  /// Exports all app data to a ZIP file containing JSON + images, then opens share dialog.
  static Future<void> exportData() async {
    try {
      final userBox = Hive.box('user_box');
      final mealBox = Hive.box('meal_box');

      final userData = <String, dynamic>{};
      for (var key in userBox.keys) {
        if (key.toString() == 'theme_mode') continue;
        userData[key.toString()] = userBox.get(key);
      }

      final mealData = mealBox.values.toList();

      // Collect images and build a mapping: original path → archive filename
      final Map<String, String> imageMap = {};
      int imgIndex = 0;

      for (var meal in mealData) {
        String? imgPath;
        if (meal is Map && meal['image_path'] != null) {
          imgPath = meal['image_path']?.toString();
        } else {
          try {
            imgPath = (meal as dynamic).imagePath?.toString();
          } catch (_) {}
        }
        if (imgPath != null && imgPath.isNotEmpty && !imageMap.containsKey(imgPath)) {
          final ext = imgPath.split('.').last;
          imageMap[imgPath] = 'images/img_$imgIndex.$ext';
          imgIndex++;
        }
      }

      // Update meal data to use archive-relative paths
      final exportMealData = mealData.map((meal) {
        Map<String, dynamic> mapped;
        if (meal is Map) {
          mapped = Map<String, dynamic>.from(meal);
        } else {
          try {
            mapped = (meal as dynamic).toJson();
          } catch (e) {
            mapped = {};
          }
        }
        
        final origPath = mapped['image_path']?.toString() ?? mapped['imagePath']?.toString();
        if (origPath != null && imageMap.containsKey(origPath)) {
          mapped['image_path'] = imageMap[origPath];
        }
        return mapped;
      }).toList();

      final fullData = {
        'user_data': userData,
        'meal_data': exportMealData,
        'exported_at': DateTime.now().toIso8601String(),
        'app': 'Calx',
        'version': 2, // v2 = ZIP format with images
      };

      final jsonString = jsonEncode(fullData);

      // Build the ZIP archive
      final archive = Archive();

      // Add JSON data
      final jsonBytes = utf8.encode(jsonString);
      archive.addFile(ArchiveFile('calx_backup.json', jsonBytes.length, jsonBytes));

      // Add image files
      for (final entry in imageMap.entries) {
        final file = File(entry.key);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          archive.addFile(ArchiveFile(entry.value, bytes.length, bytes));
        }
      }

      // Encode and save the ZIP
      final zipBytes = ZipEncoder().encode(archive);

      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final zipFile = File('${directory.path}/calx_backup_$timestamp.zip');
      await zipFile.writeAsBytes(zipBytes);

      await Share.shareXFiles(
        [XFile(zipFile.path, mimeType: 'application/zip')],
        subject: 'Calx Data Backup',
        text:
            'Backup of my Calx app data from ${DateTime.now().toString().split('.')[0]}',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Imports app data from a JSON or ZIP file selected by the user.
  /// Returns [true] if import was successful, [false] otherwise.
  static Future<bool> importData() async {
    try {
      if (Platform.isAndroid) {
        await Permission.storage.request();
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'zip'],
        withData: true,
      );

      if (result != null) {
        final platformFile = result.files.single;
        final name = platformFile.name.toLowerCase();
        final ext = platformFile.extension?.toLowerCase();

        bool isZip = ext == 'zip' || name.endsWith('.zip');

        if (!isZip) {
          try {
            Uint8List? fileBytes = platformFile.bytes;
            if (fileBytes == null && platformFile.path != null) {
              fileBytes = await File(platformFile.path!).readAsBytes();
            }
            if (fileBytes != null && fileBytes.length > 4) {
              if (fileBytes[0] == 0x50 && fileBytes[1] == 0x4B) {
                isZip = true;
              }
            }
          } catch (_) {}
        }

        if (isZip) {
          return await _processZipImport(platformFile);
        } else {
          // Legacy JSON import (backward compatibility)
          String jsonString;
          try {
            if (platformFile.bytes != null) {
              jsonString = utf8.decode(platformFile.bytes!, allowMalformed: true);
            } else if (platformFile.path != null) {
              final file = File(platformFile.path!);
              jsonString = await file.readAsString();
            } else {
              return false;
            }
            final decoded = jsonDecode(jsonString);
            if (decoded is Map<String, dynamic>) {
              return await _processImport(decoded, null);
            } else if (decoded is List) {
              return await _processLegacyListImport(decoded);
            }
          } catch (e) {
            // If it failed to completely decode as JSON, it might be a ZIP without recognized extension
            return await _processZipImport(platformFile);
          }
          return false;
        }
      }
      return false;
    } catch (e) {
      debugPrint("Import Error: $e");
      return false;
    }
  }

  /// Processes a ZIP backup file — extracts images and restores JSON data.
  static Future<bool> _processZipImport(PlatformFile platformFile) async {
    try {
      Uint8List? zipBytes;
      if (platformFile.bytes != null) {
        zipBytes = platformFile.bytes!;
      } else if (platformFile.path != null) {
        zipBytes = await File(platformFile.path!).readAsBytes();
      }
      if (zipBytes == null) return false;

      final archive = ZipDecoder().decodeBytes(zipBytes);

      // Find the JSON file in the archive
      ArchiveFile? jsonFile;
      for (final file in archive.files) {
        if (file.name.endsWith('.json')) {
          jsonFile = file;
          break;
        }
      }
      if (jsonFile == null) {
        debugPrint("No JSON file found in ZIP");
        return false;
      }

      final jsonString = utf8.decode(jsonFile.content as List<int>);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // Extract images to app document directory
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/calx_images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final Map<String, String> imagePathMap = {};
      for (final file in archive.files) {
        if (file.name.startsWith('images/') && !file.isFile == false) {
          if (file.isFile) {
            final localPath = '${imagesDir.path}/${file.name.split('/').last}';
            final outFile = File(localPath);
            await outFile.writeAsBytes(file.content as List<int>);
            imagePathMap[file.name] = localPath;
          }
        }
      }

      return await _processImport(data, imagePathMap);
    } catch (e) {
      debugPrint("ZIP Import Error: $e");
      return false;
    }
  }

  static Future<bool> _processImport(
    Map<String, dynamic> data,
    Map<String, String>? imagePathMap,
  ) async {
    try {
      if (data.containsKey('user_data') && data.containsKey('meal_data')) {
        final userBox = Hive.box('user_box');
        final mealBox = Hive.box('meal_box');

        await userBox.clear();
        await mealBox.clear();

        // Restore user data
        final userData = data['user_data'] as Map<String, dynamic>;
        for (var entry in userData.entries) {
          if (entry.key == 'theme_mode') continue;
          await userBox.put(entry.key, entry.value);
        }

        // Always force light theme after import
        await userBox.put('theme_mode', 'light');

        // Restore meal data with image path remapping
        final mealData = data['meal_data'] as List;
        for (var meal in mealData) {
          if (meal is Map) {
            final mapped = Map<String, dynamic>.from(meal);
            // Remap image paths from archive-relative to local paths
            if (imagePathMap != null && mapped['image_path'] != null) {
              final archivePath = mapped['image_path'].toString();
              if (imagePathMap.containsKey(archivePath)) {
                mapped['image_path'] = imagePathMap[archivePath];
              }
            }
            await mealBox.add(mapped);
          } else {
            await mealBox.add(meal);
          }
        }

        debugPrint(
          "Imported ${userData.length} user settings and ${mealData.length} meals"
          "${imagePathMap != null ? ' with ${imagePathMap.length} images' : ''}.",
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

  static Future<bool> _processLegacyListImport(List data) async {
    try {
      final mealBox = Hive.box('meal_box');
      await mealBox.clear();
      for (var meal in data) {
        if (meal is Map) {
          await mealBox.add(Map<String, dynamic>.from(meal));
        } else {
          try {
            await mealBox.add(meal);
          } catch (e) {
            // error
          }
        }
      }
      return true;
    } catch (e) {
      debugPrint("Process Legacy List Import Error: $e");
      return false;
    }
  }
}
