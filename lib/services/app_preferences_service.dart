import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

class AppPreferencesService {
  static String prefsFilePath(String notesDirectory) => p.join(notesDirectory, '.flutternotes.json');

  static Future<void> ensurePrefsFileExists(String notesDirectory) async {
    final file = File(prefsFilePath(notesDirectory));
    if (!await file.exists()) {
      await file.writeAsString(json.encode({"tags": {}}), flush: true);
    }
  }

  static Future<Map<String, dynamic>> readPrefs(String notesDirectory) async {
    await ensurePrefsFileExists(notesDirectory);
    final file = File(prefsFilePath(notesDirectory));
    final content = await file.readAsString();
    return json.decode(content) as Map<String, dynamic>;
  }

  static Future<void> writePrefs(String notesDirectory, Map<String, dynamic> prefs) async {
    await ensurePrefsFileExists(notesDirectory);
    final file = File(prefsFilePath(notesDirectory));
    try {
      await file.writeAsString(json.encode(prefs), flush: true);
      print('Fichier .flutternotes.json écrit avec succès.');
    } catch (e) {
      print('Erreur lors de l\'écriture de .flutternotes.json : $e');
    }
  }

  static Future<Map<String, List<String>>> getTagsMapping(String notesDirectory) async {
    final prefs = await readPrefs(notesDirectory);
    final tags = prefs['tags'] as Map<String, dynamic>? ?? {};
    return tags.map((k, v) => MapEntry(k, (v as List).cast<String>()));
  }

  static Future<void> setTagsMapping(String notesDirectory, Map<String, List<String>> tagsMapping) async {
    print('Écriture des tags dans $notesDirectory/.flutternotes.json : $tagsMapping');
    final prefs = await readPrefs(notesDirectory);
    prefs['tags'] = tagsMapping;
    await writePrefs(notesDirectory, prefs);
  }
} 