import 'dart:convert';
import 'dart:io';

class NotesMetaService {
  static const String metaFileName = '.flutternotesmeta.json';

  static String metaFilePath(String notesDirectory) {
    return '$notesDirectory/$metaFileName';
  }

  static Future<List<String>> readTags(String notesDirectory) async {
    final file = File(metaFilePath(notesDirectory));
    if (await file.exists()) {
      final content = await file.readAsString();
      final jsonData = json.decode(content);
      final tags = (jsonData['tags'] as List?)?.cast<String>() ?? [];
      return tags;
    }
    return [];
  }

  static Future<void> writeTags(String notesDirectory, List<String> tags) async {
    final file = File(metaFilePath(notesDirectory));
    final jsonData = {'tags': tags};
    await file.writeAsString(json.encode(jsonData), flush: true);
  }

  static Future<void> initWithTags(String notesDirectory, List<String> tags) async {
    final file = File(metaFilePath(notesDirectory));
    if (!await file.exists()) {
      await writeTags(notesDirectory, tags);
    }
  }
} 