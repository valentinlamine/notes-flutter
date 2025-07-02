import 'dart:convert';
import 'dart:io';

class NotesMetaService {
  static const String metaFileName = '.flutternotesmeta.json';

  /// Récupère le chemin complet du fichier meta dans le dossier de notes
  static String metaFilePath(String notesDirectory) {
    return '$notesDirectory/$metaFileName';
  }

  /// Lit la liste des tags depuis le fichier meta
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

  /// Écrit la liste des tags dans le fichier meta
  static Future<void> writeTags(String notesDirectory, List<String> tags) async {
    final file = File(metaFilePath(notesDirectory));
    final jsonData = {'tags': tags};
    await file.writeAsString(json.encode(jsonData), flush: true);
  }

  /// Initialise le fichier meta à partir d'une liste de tags
  static Future<void> initWithTags(String notesDirectory, List<String> tags) async {
    final file = File(metaFilePath(notesDirectory));
    if (!await file.exists()) {
      await writeTags(notesDirectory, tags);
    }
  }
} 