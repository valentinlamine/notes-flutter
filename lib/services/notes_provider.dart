import 'package:flutter/foundation.dart';
import '../models/note.dart';
import 'database_service.dart';

class NotesProvider with ChangeNotifier {
  List<Note> _notes = [];
  List<String> _allTags = [];
  String? _selectedTag;

  final DatabaseService _databaseService = DatabaseService();

  List<Note> get notes => _notes;
  List<String> get allTags => _allTags;
  String? get selectedTag => _selectedTag;

  NotesProvider() {
    fetchNotes();
  }

  Future<void> fetchNotes() async {
    _notes = await _databaseService.getNotes();
    _extractAllTags();
    notifyListeners();
  }

  Future<void> fetchNotesByTag(String tag) async {
    _selectedTag = tag;
    final allNotes = await _databaseService.getNotes();
    _notes = allNotes.where((note) => note.tags.contains(tag)).toList();
    notifyListeners();
  }

  Future<void> addNote(Note note) async {
    final id = await _databaseService.insertNote(note);
    final newNote = Note(
      id: id,
      title: note.title,
      content: note.content,
      tags: note.tags,
      createdAt: note.createdAt,
      updatedAt: note.updatedAt,
    );
    _notes.insert(0, newNote);
    _extractAllTags();
    notifyListeners();
  }

  Future<void> updateNote(Note note) async {
    await _databaseService.updateNote(note);
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index >= 0) {
      _notes[index] = note;
    }
    _extractAllTags();
    notifyListeners();
  }

  Future<void> deleteNote(int id) async {
    await _databaseService.deleteNote(id);
    _notes.removeWhere((note) => note.id == id);
    _extractAllTags();
    notifyListeners();
  }

  void _extractAllTags() {
    Set<String> uniqueTags = {};
    for (var note in _notes) {
      uniqueTags.addAll(note.tags);
    }
    _allTags = uniqueTags.toList()..sort();
  }

  void clearTagFilter() {
    _selectedTag = null;
    fetchNotes();
  }

  void debugPrintNotes() {
    print('=== DEBUG NOTES ===');
    for (var note in _notes) {
      print('Note: ${note.title}, Tags: ${note.tags}');
    }
    print('All tags: $_allTags');
    print('Selected tag: $_selectedTag');
  }

  Future<void> debugDatabase() async {
    await _databaseService.debugDatabase();
  }
} 