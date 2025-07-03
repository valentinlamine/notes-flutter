import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_selector/file_selector.dart';
import '../models/note.dart';
import 'notes_meta_service.dart';
import 'app_preferences_service.dart';
import 'package:path/path.dart' as p;
import 'package:process_run/process_run.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'notes_sync_service.dart'; // Pour la synchro cloud
import 'dart:async';
import 'package:uuid/uuid.dart';

class NotesProvider with ChangeNotifier {
  List<Note> _notes = [];
  Map<String, List<String>> _tagsMapping = {};
  String? _selectedTag;
  Note? _selectedNote;
  String? _notesDirectory;
  bool hasDirectoryPermission = true;

  static const _prefsKey = 'notes_directory_path';

  List<Note> get notes => _notes;
  List<String> get allTags => _tagsMapping.keys.toList()..sort();
  String? get selectedTag => _selectedTag;
  Note? get selectedNote => _selectedNote;
  String? get notesDirectory => _notesDirectory;
  bool get directoryPermissionOk => hasDirectoryPermission;

  NotesProvider() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDir = prefs.getString(_prefsKey);
    if (savedDir != null && Directory(savedDir).existsSync()) {
      _notesDirectory = savedDir;
      await loadNotes();
    }
    notifyListeners();
  }

  Future<bool> chooseNotesDirectory() async {
    final directory = await getDirectoryPath();
    if (directory != null) {
      _notesDirectory = directory;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, directory);
      await loadNotes();
      notifyListeners();
      return true;
    } else {
      return false;
    }
  }

  Future<void> loadNotes() async {
    if (_notesDirectory == null) return;
    final dir = Directory(_notesDirectory!);
    try {
      if (!await dir.exists()) throw Exception('Dossier introuvable');
      hasDirectoryPermission = true;
      final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.md')).toList();
      _notes = await Future.wait(files.map((f) async {
        final note = await Note.fromFile(f);
        await _ensureNoteHeader(note);
        return note;
      }));
      _deduplicateNotes();
      _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      await _rebuildAndSaveTagsMapping();
      notifyListeners();
    } catch (e) {
      hasDirectoryPermission = false;
      notifyListeners();
    }
  }

  Future<void> _ensureNoteHeader(Note note) async {
    bool changed = false;
    if (note.id.isEmpty) {
      note.id = const Uuid().v4();
      changed = true;
    }
    if (note.title.isEmpty) {
      note.title = p.basenameWithoutExtension(note.filePath);
      changed = true;
    }
    if (note.createdAt == null) {
      note.createdAt = DateTime.now();
      changed = true;
    }
    if (note.updatedAt == null) {
      note.updatedAt = DateTime.now();
      changed = true;
    }
    if (changed) {
      await note.saveToFile();
    }
  }

  void _deduplicateNotes() {
    final seen = <String, Note>{};
    for (final note in _notes) {
      final key = note.id;
      if (!seen.containsKey(key)) {
        seen[key] = note;
      } else {
        if (note.updatedAt.isAfter(seen[key]!.updatedAt)) {
          seen[key] = note;
        }
      }
    }
    _notes = seen.values.toList();
    _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> createNote(String title) async {
    if (_notesDirectory == null) return;
    final safeTitle = title.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final fileName = '$safeTitle.md';
    final filePath = '$_notesDirectory/$fileName';
    if (File(filePath).existsSync()) {
      throw Exception('Une note avec ce nom existe déjà.');
    }
    final note = Note(filePath: filePath, title: title, content: '', tags: []);
    await note.saveToFile();
    await loadNotes();
    selectNote(note);
  }

  Future<void> saveNote(Note note, {String? newTitle}) async {
    note.updatedAt = DateTime.now();
    if (newTitle != null && newTitle.trim().isNotEmpty && newTitle != note.title) {
      final safeTitle = newTitle.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final newFileName = '$safeTitle.md';
      final newFilePath = '$_notesDirectory/$newFileName';
      final oldFile = File(note.filePath);
      final newFile = File(newFilePath);
      if (await newFile.exists()) {
        throw Exception('Une note avec ce nom existe déjà.');
      }
      await oldFile.rename(newFilePath);
      note.filePath = newFilePath;
      note.title = newTitle;
    }
    await _ensureNoteHeader(note);
    await note.saveToFile();
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _notes[index] = note;
    }
    _deduplicateNotes();
    _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    await _rebuildAndSaveTagsMapping();
    selectNote(note);
    notifyListeners();
  }

  Future<void> deleteNote(Note note) async {
    await note.deleteFile();
    await loadNotes();
    _deduplicateNotes();
    selectNote(null);
  }

  void selectNote(Note? note) {
    _selectedNote = note;
    notifyListeners();
  }

  List<Note> notesForTag(String tag) {
    final fileNames = _tagsMapping[tag] ?? [];
    return _notes.where((n) => fileNames.contains(p.basename(n.filePath))).toList();
  }

  List<Note> notesForTags(List<String> tags) {
    if (tags.isEmpty) return _notes;
    final sets = tags.map((t) => Set<String>.from(_tagsMapping[t] ?? const <String>[])).toList();
    Set<String> intersection;
    if (sets.isEmpty) {
      intersection = <String>{};
    } else {
      intersection = sets.first;
      for (final s in sets.skip(1)) {
        intersection = intersection.intersection(s);
      }
    }
    return _notes.where((n) => intersection.contains(p.basename(n.filePath))).toList();
  }

  Future<void> importNote(String title, String content) async {
    if (_notesDirectory == null) return;
    final safeTitle = title.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final fileName = '$safeTitle.md';
    final filePath = '$_notesDirectory/$fileName';
    if (File(filePath).existsSync()) {
      throw Exception('Une note avec ce nom existe déjà.');
    }
    final note = Note(filePath: filePath, title: title, content: content, tags: []);
    await _ensureNoteHeader(note);
    await note.saveToFile();
    await loadNotes();
    selectNote(note);
  }

  void clearNotesDirectory() {
    _notesDirectory = null;
    _notes = [];
    _tagsMapping = {};
    _selectedNote = null;
    _selectedTag = null;
    notifyListeners();
  }

  Future<void> deleteAllNotesAndPrefs() async {
    if (_notesDirectory == null) return;
    final dir = Directory(_notesDirectory!);
    try {
      if (await dir.exists()) {
        final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.md'));
        for (final file in files) {
          try {
            await file.delete();
          } catch (e) {
            print('Erreur lors de la suppression du fichier ${file.path} : $e');
          }
        }
        final prefsFile = File('${_notesDirectory!}/.flutternotes.json');
        if (await prefsFile.exists()) {
          try { await prefsFile.delete(); } catch (e) { print('Erreur suppression prefs : $e'); }
        }
        final metaFile = File('${_notesDirectory!}/.flutternotesmeta.json');
        if (await metaFile.exists()) {
          try { await metaFile.delete(); } catch (e) { print('Erreur suppression meta : $e'); }
        }
      }
    } catch (e) {
      print('Erreur lors de la suppression des fichiers utilisateur : $e');
    }
    clearNotesDirectory();
  }

  Future<void> _rebuildAndSaveTagsMapping() async {
    if (_notesDirectory == null) return;
    try {
      final Map<String, List<String>> tagsMap = {};
      for (final note in _notes) {
        final fileName = p.basename(note.filePath);
        for (final tag in note.tags) {
          tagsMap.putIfAbsent(tag, () => []).add(fileName);
        }
      }
      _tagsMapping = tagsMap;
      await AppPreferencesService.setTagsMapping(_notesDirectory!, _tagsMapping);
    } catch (e, st) {
      print('Erreur lors de la reconstruction/écriture du mapping des tags : $e\n$st');
    }
  }

  Future<void> revealInFinder(Note note) async {
    final file = File(note.filePath);
    if (await file.exists()) {
      if (Platform.isMacOS) {
        await Process.run('open', ['-R', file.path]);
      } else if (Platform.isWindows) {
        await Process.run('explorer', ['/select,${file.path.replaceAll('/', '\\')}']);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [file.parent.path]);
      }
    } else {
      print('Fichier introuvable : ${file.path}');
    }
  }

  Future<bool> moveNotesToNewDirectory(BuildContext context) async {
    if (_notesDirectory == null) return false;
    final oldDir = Directory(_notesDirectory!);
    final newDirPath = await getDirectoryPath();
    if (newDirPath == null) return false;
    final newDir = Directory(newDirPath);
    try {
      if (!await newDir.exists()) await newDir.create(recursive: true);
      // Copie toutes les notes .md
      final noteFiles = oldDir.listSync().whereType<File>().where((f) => f.path.endsWith('.md'));
      for (final file in noteFiles) {
        final newFile = File(p.join(newDirPath, p.basename(file.path)));
        await file.copy(newFile.path);
      }
      // Copie les fichiers de prefs/meta
      final prefsFile = File(p.join(_notesDirectory!, '.flutternotes.json'));
      if (await prefsFile.exists()) {
        await prefsFile.copy(p.join(newDirPath, '.flutternotes.json'));
      }
      final metaFile = File(p.join(_notesDirectory!, '.flutternotesmeta.json'));
      if (await metaFile.exists()) {
        await metaFile.copy(p.join(newDirPath, '.flutternotesmeta.json'));
      }
      // Met à jour le chemin dans les prefs
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, newDirPath);
      _notesDirectory = newDirPath;
      await loadNotes();
      notifyListeners();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dossier de notes changé avec succès.')),
        );
      }
      return true;
    } catch (e) {
      print('[ERROR] Erreur lors du transfert des notes : $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du transfert : $e')),
        );
      }
      return false;
    }
  }
} 