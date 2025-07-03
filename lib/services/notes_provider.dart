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

class NotesProvider with ChangeNotifier {
  List<Note> _notes = [];
  Map<String, List<String>> _tagsMapping = {};
  String? _selectedTag;
  Note? _selectedNote;
  String? _notesDirectory;
  bool hasDirectoryPermission = true;

  static const _prefsKey = 'notes_directory_path';

  // Ajout du callback pour l'UI
  VoidCallback? onDirectoryAccessError;

  final NotesSyncService _syncService = NotesSyncService();

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
    print('[DEBUG] Chemin du dossier de notes retrouvé dans prefs : $savedDir');
    if (savedDir != null && Directory(savedDir).existsSync()) {
      _notesDirectory = savedDir;
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
      print('[DEBUG] Chemin du dossier de notes sauvegardé dans prefs : $directory');
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
    try {
      if (!await dir.exists()) throw Exception('Dossier introuvable');
      hasDirectoryPermission = true;
      final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.md')).toList();
      _notes = await Future.wait(files.map((f) => Note.fromFile(f)));
      _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      await _rebuildAndSaveTagsMapping();
      // Synchronisation cloud : pull
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final remoteNotes = await _syncService.pullNotes(user.id);
        // Fusionner les notes locales et distantes (simple : si remote plus récent, remplacer local)
        for (final remote in remoteNotes) {
          final local = _notes.firstWhere(
            (n) => n.remoteId == remote.remoteId || n.title == remote.title,
            orElse: () => remote,
          );
          if (local.updatedAt.isBefore(remote.updatedAt)) {
            // Remplacer local par distant
            final file = File('${_notesDirectory!}/${remote.title}.md');
            await file.writeAsString(remote.content);
            local.content = remote.content;
            local.tags = remote.tags;
            local.updatedAt = remote.updatedAt;
            local.syncStatus = SyncStatus.synced;
            local.remoteId = remote.remoteId;
            local.lastSyncedAt = remote.updatedAt;
          } else if (local.updatedAt.isAfter(remote.updatedAt)) {
            // Local plus récent : marquer comme à synchroniser
            local.syncStatus = SyncStatus.notSynced;
          } else {
            local.syncStatus = SyncStatus.synced;
          }
        }
      }
      notifyListeners();
    } catch (e) {
      print('[ERROR] Impossible d\'accéder au dossier de notes : $e');
      hasDirectoryPermission = false;
      notifyListeners();
      if (onDirectoryAccessError != null) {
        onDirectoryAccessError!();
      }
    }
  }

  Future<void> _rebuildAndSaveTagsMapping() async {
    if (_notesDirectory == null) return;
    try {
      print('Reconstruction du mapping tags. Nombre de notes : [33m${_notes.length}[0m');
      final Map<String, List<String>> tagsMap = {};
      for (final note in _notes) {
        final fileName = p.basename(note.filePath);
        print('Note : [36m${note.title}[0m | Fichier : [36m$fileName[0m | Tags : [32m${note.tags}[0m');
        for (final tag in note.tags) {
          tagsMap.putIfAbsent(tag, () => []).add(fileName);
        }
      }
      print('Mapping tags à écrire : [35m$tagsMap[0m');
      _tagsMapping = tagsMap;
      await AppPreferencesService.setTagsMapping(_notesDirectory!, _tagsMapping);
    } catch (e, st) {
      print('Erreur lors de la reconstruction/écriture du mapping des tags : $e\n$st');
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

  Future<void> saveNote(Note note) async {
    note.updatedAt = DateTime.now();
    await note.saveToFile();

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      note.syncStatus = SyncStatus.syncing;
      notifyListeners();
      try {
        await _syncService.pushNote(note, user.id);
      } catch (e) {
        print('Erreur push note: $e');
        note.syncStatus = SyncStatus.notSynced;
      }
    }

    final index = _notes.indexWhere((n) => n.filePath == note.filePath);
    if (index != -1) {
      _notes[index] = note;
    }
    _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    await _rebuildAndSaveTagsMapping();
    
    selectNote(note);
    notifyListeners();
  }

  void selectNote(Note? note) {
    _selectedNote = note;
    notifyListeners();
  }

  // Pour ouvrir le fichier dans le Finder/Explorateur
  Future<void> revealInFinder(Note note) async {
    final file = File(note.filePath);
    if (await file.exists()) {
      if (Platform.isMacOS) {
        await run('open -R "${file.path}"');
      } else if (Platform.isWindows) {
        await run('explorer.exe /select,"${file.path}"');
      } else if (Platform.isLinux) {
        await run('xdg-open "${file.parent.path}"');
      }
    }
  }

  Future<void> deleteNote(Note note) async {
    await note.deleteFile();
    await loadNotes();
    selectNote(null);
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
        // Supprime tous les fichiers .md
        final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.md'));
        for (final file in files) {
          try {
            await file.delete();
          } catch (e) {
            print('Erreur lors de la suppression du fichier ${file.path} : $e');
          }
        }
        // Supprime les fichiers de prefs/meta
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

  static Future<bool> deleteAccountWithEdgeFunction(String supabaseUrl) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;
    final accessToken = Supabase.instance.client.auth.currentSession?.accessToken;
    if (accessToken == null) return false;
    final functionUrl = '$supabaseUrl/functions/v1/delete_user';
    final response = await http.post(
      Uri.parse(functionUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: '{"user": {"id": "${user.id}"}}',
    );
    if (response.statusCode == 200) {
      return true;
    } else {
      print('Erreur suppression compte: \\n${response.body}');
      return false;
    }
  }

  /// Déplace toutes les notes et fichiers de prefs/meta vers un nouveau dossier choisi par l'utilisateur
  Future<bool> moveNotesToNewDirectory(BuildContext context) async {
    if (_notesDirectory == null) return false;
    final oldDir = Directory(_notesDirectory!);
    final newDirPath = await getDirectoryPath();
    if (newDirPath == null) return false;
    final newDir = Directory(newDirPath);
    try {
      // Crée le dossier cible s'il n'existe pas
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dossier de notes changé avec succès.')),
      );
      return true;
    } catch (e) {
      print('[ERROR] Erreur lors du transfert des notes : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du transfert : $e')),
      );
      return false;
    }
  }

  void resetDirectoryAccessError() {
    hasDirectoryPermission = true;
    onDirectoryAccessError = null;
  }

  Future<void> forceSync({bool showSnackbar = true, BuildContext? context}) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (showSnackbar && context != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vous devez être connecté pour synchroniser.')));
      }
      return;
    }

    if (showSnackbar && context != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Synchronisation en cours...')));
    }

    final remoteNotes = await _syncService.pullNotes(user.id);

    for (final remoteNote in remoteNotes) {
      final localMatchIndex = _notes.indexWhere((n) => n.remoteId == remoteNote.remoteId);

      if (localMatchIndex != -1) {
        final localNote = _notes[localMatchIndex];
        if (remoteNote.updatedAt.isAfter(localNote.updatedAt)) {
          localNote.title = remoteNote.title;
          localNote.content = remoteNote.content;
          localNote.tags = remoteNote.tags;
          localNote.updatedAt = remoteNote.updatedAt;
          localNote.syncStatus = SyncStatus.synced;
          localNote.lastSyncedAt = remoteNote.updatedAt;
          await localNote.saveToFile();
        }
      } else {
        remoteNote.filePath = '${_notesDirectory!}/${remoteNote.title}.md';
        await remoteNote.saveToFile();
        _notes.add(remoteNote);
      }
    }
    
    final unsyncedNotes = _notes.where((n) => n.syncStatus == SyncStatus.notSynced).toList();
    for (final note in unsyncedNotes) {
      note.syncStatus = SyncStatus.syncing;
      notifyListeners();
      try {
        await _syncService.pushNote(note, user.id);
      } catch (e) {
        print('Erreur push : $e');
        note.syncStatus = SyncStatus.notSynced;
      }
    }

    _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    await _rebuildAndSaveTagsMapping();
    notifyListeners();
    if (showSnackbar && context != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Synchronisation terminée.')));
    }
  }
} 