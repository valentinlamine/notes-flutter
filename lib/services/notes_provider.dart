import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_selector/file_selector.dart';
import '../models/note.dart';
import 'notes_meta_service.dart';

class NotesProvider with ChangeNotifier {
  List<Note> _notes = [];
  List<String> _allTags = [];
  String? _selectedTag;
  Note? _selectedNote;
  String? _notesDirectory;

  static const _prefsKey = 'notes_directory_path';

  List<Note> get notes => _notes;
  List<String> get allTags => _allTags;
  String? get selectedTag => _selectedTag;
  Note? get selectedNote => _selectedNote;
  String? get notesDirectory => _notesDirectory;

  NotesProvider() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _notesDirectory = prefs.getString(_prefsKey);
    if (_notesDirectory != null) {
      await loadNotes();
    }
    notifyListeners();
  }

  Future<bool> chooseNotesDirectory() async {
    print('Ouverture du sélecteur de dossier...');
    final directory = await getDirectoryPath();
    print('Résultat getDirectoryPath: $directory');
    if (directory != null) {
      _notesDirectory = directory;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, directory);
      await loadNotes();
      notifyListeners();
      print('Dossier sélectionné et enregistré: $directory');
      return true;
    } else {
      print('Aucun dossier sélectionné.');
      return false;
    }
  }

  Future<void> loadNotes() async {
    if (_notesDirectory == null) return;
    final dir = Directory(_notesDirectory!);
    if (!await dir.exists()) return;
    final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.md')).toList();
    _notes = await Future.wait(files.map((f) => Note.fromFile(f)));
    _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    await _syncTagsWithMeta();
    notifyListeners();
  }

  Future<void> _syncTagsWithMeta() async {
    if (_notesDirectory == null) return;
    // On tente de lire les tags du fichier meta
    final metaTags = await NotesMetaService.readTags(_notesDirectory!);
    if (metaTags.isNotEmpty) {
      _allTags = metaTags;
    } else {
      // Si le fichier n'existe pas ou est vide, on reconstruit la liste à partir des notes
      final tagsSet = <String>{};
      for (final note in _notes) {
        tagsSet.addAll(note.tags);
      }
      _allTags = tagsSet.toList()..sort();
      await NotesMetaService.writeTags(_notesDirectory!, _allTags);
    }
  }

  void _extractAllTags() {}

  void clearTagFilter() {
    _selectedTag = null;
  }

  void filterNotesByTags(List<String> tags) {}

  Future<void> createNote(String title) async {
    if (_notesDirectory == null) return;
    final safeTitle = title.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final filePath = '$_notesDirectory/$safeTitle.md';
    final note = Note(filePath: filePath, title: title, content: '', tags: []);
    await note.saveToFile();
    await loadNotes();
    await _syncTagsWithMeta();
    selectNote(note);
  }

  Future<void> saveNote(Note note) async {
    await note.saveToFile();
    await loadNotes();
    await _syncTagsWithMeta();
    selectNote(note);
  }

  void selectNote(Note? note) {
    _selectedNote = note;
    notifyListeners();
  }

  // Pour ouvrir le fichier dans le Finder/Explorateur
  Future<void> revealInFinder(Note note) async {
    final file = File(note.filePath);
    if (await file.exists()) {
      await openFile(initialDirectory: file.parent.path);
    }
  }

  Future<void> deleteNote(Note note) async {
    await note.deleteFile();
    await loadNotes();
    await _syncTagsWithMeta();
    selectNote(null);
  }
} 