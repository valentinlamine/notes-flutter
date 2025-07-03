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
import '../screens/welcome_screen.dart';

class NotesProvider with ChangeNotifier {
  List<Note> _notes = [];
  Map<String, List<String>> _tagsMapping = {};
  String? _selectedTag;
  Note? _selectedNote;
  String? _notesDirectory;
  bool hasDirectoryPermission = true;
  String? _deviceId;

  static const _prefsKey = 'notes_directory_path';

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
    _deviceId = prefs.getString('device_id');
    if (_deviceId == null) {
      _deviceId = const Uuid().v4();
      await prefs.setString('device_id', _deviceId!);
    }
    if (savedDir != null && Directory(savedDir).existsSync()) {
      _notesDirectory = savedDir;
      await loadNotes();
      // Synchro auto au démarrage si utilisateur connecté
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await forceSync();
      }
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
      // Synchro auto après ouverture du dossier si utilisateur connecté
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await forceSync();
      }
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
      // Sauvegarde l'état de sync des notes déjà en mémoire
      final Map<String, SyncStatus> oldStatus = { for (var n in _notes) n.id : n.syncStatus };
      final Map<String, DateTime?> oldLastSynced = { for (var n in _notes) n.id : n.lastSyncedAt };
      final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.md')).toList();
      _notes = await Future.wait(files.map((f) async {
        final note = await Note.fromFile(f);
        await _ensureNoteHeader(note);
        // Restaure le statut de sync si déjà connu
        note.syncStatus = oldStatus[note.id] ?? SyncStatus.notSynced;
        note.lastSyncedAt = oldLastSynced[note.id];
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

  Future<void> createNote(String title, {BuildContext? context}) async {
    if (_notesDirectory == null) return;
    final safeTitle = title.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final fileName = '$safeTitle.md';
    final filePath = '$_notesDirectory/$fileName';
    if (File(filePath).existsSync()) {
      throw Exception('Une note avec ce nom existe déjà.');
    }
    final note = Note(filePath: filePath, title: title, content: '', tags: [], syncStatus: SyncStatus.notSynced);
    note.lastModifiedBy = _deviceId ?? '';
    await note.saveToFile();
    await loadNotes();
    selectNote(note);
    if (context != null) await _syncWithDelay(context);
  }

  Future<void> saveNote(Note note, {String? newTitle, BuildContext? context}) async {
    note.updatedAt = DateTime.now();
    note.lastModifiedBy = _deviceId ?? '';
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
    if (context != null) await _syncWithDelay(context);
  }

  Future<void> deleteNote(Note note, {BuildContext? context}) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && note.remoteId != null) {
      await _syncService.deleteNoteCloud(note, user.id);
    }
    // Suppression locale
    await note.deleteFile();
    _notes.removeWhere((n) => n.id == note.id);
    notifyListeners();
    if (context != null) await _syncWithDelay(context);
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
      // Synchro auto après changement de dossier si utilisateur connecté
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await forceSync();
      }
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

  Future<void> forceSync({BuildContext? context}) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expirée, veuillez vous reconnecter.')),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (route) => false,
        );
      }
      return;
    }
    final userId = user.id;
    // 1. Pousser toutes les notes locales modifiées/non synchronisées
    for (final note in _notes) {
      try {
        if (note.syncStatus != SyncStatus.synced) {
          note.syncStatus = SyncStatus.syncing;
          notifyListeners();
          await _syncService.pushNote(note, userId);
        }
      } on AuthException catch (_) {
        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session expirée, veuillez vous reconnecter.')),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const WelcomeScreen()),
            (route) => false,
          );
        }
        return;
      } catch (e) {
        print('[SYNC][ERROR] pushNote: $e');
        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur de synchronisation : $e')),
          );
        }
        note.syncStatus = SyncStatus.notSynced;
        notifyListeners();
      }
    }
    // 2. Récupérer toutes les notes du cloud
    List<Note> remoteNotes = [];
    try {
      remoteNotes = await _syncService.pullNotes(userId);
    } on AuthException catch (_) {
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expirée, veuillez vous reconnecter.')),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (route) => false,
        );
      }
      return;
    } catch (e) {
      print('[SYNC][ERROR] pullNotes: $e');
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de synchronisation : $e')),
        );
      }
      return;
    }
    // 3. Fusionner local et cloud
    for (final remote in remoteNotes) {
      final localIdx = _notes.indexWhere((n) => n.id == remote.id);
      if (localIdx == -1) {
        // Nouvelle note distante, ajouter localement
        final newNote = Note(
          id: remote.id,
          filePath: '$_notesDirectory/${remote.title.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}.md',
          title: remote.title,
          content: remote.content,
          tags: remote.tags,
          createdAt: remote.createdAt,
          updatedAt: remote.updatedAt,
          syncStatus: SyncStatus.synced,
          lastSyncedAt: remote.updatedAt,
          deleted: remote.deleted,
        );
        await newNote.saveToFile();
        _notes.add(newNote);
      } else {
        final local = _notes[localIdx];
        final lastSynced = local.lastSyncedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final localChanged = local.updatedAt.isAfter(lastSynced);
        final remoteChanged = remote.updatedAt.isAfter(lastSynced);
        if (localChanged && remoteChanged && remote.updatedAt != local.updatedAt) {
          if (local.lastModifiedBy != null && remote.lastModifiedBy != null && local.lastModifiedBy == remote.lastModifiedBy) {
            await _syncService.pushNote(local, userId);
            local.syncStatus = SyncStatus.synced;
            local.lastSyncedAt = DateTime.now();
          } else {
            local.syncStatus = SyncStatus.conflict;
            notifyListeners();
            if (context != null) {
              await showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Conflit de synchronisation'),
                  content: Text('La note "${local.title}" a été modifiée localement ET dans le cloud. Quelle version garder ?'),
                  actions: [
                    TextButton(
                      onPressed: () async {
                        await _syncService.pushNote(local, userId);
                        local.syncStatus = SyncStatus.synced;
                        local.lastSyncedAt = DateTime.now();
                        Navigator.of(ctx).pop();
                      },
                      child: const Text('Garder local'),
                    ),
                    TextButton(
                      onPressed: () async {
                        local.title = remote.title;
                        local.content = remote.content;
                        local.tags = remote.tags;
                        local.updatedAt = remote.updatedAt;
                        local.syncStatus = SyncStatus.synced;
                        local.lastSyncedAt = remote.updatedAt;
                        local.deleted = remote.deleted;
                        local.lastModifiedBy = remote.lastModifiedBy;
                        await local.saveToFile();
                        Navigator.of(ctx).pop();
                      },
                      child: const Text('Garder cloud'),
                    ),
                  ],
                ),
              );
            }
          }
        } else if (remote.updatedAt.isAfter(local.updatedAt)) {
          local.title = remote.title;
          local.content = remote.content;
          local.tags = remote.tags;
          local.updatedAt = remote.updatedAt;
          local.syncStatus = SyncStatus.synced;
          local.lastSyncedAt = remote.updatedAt;
          local.deleted = remote.deleted;
          local.lastModifiedBy = remote.lastModifiedBy;
          await local.saveToFile();
        } else {
          local.syncStatus = SyncStatus.synced;
        }
      }
    }
    // 4. Supprimer localement les notes marquées deleted dans le cloud
    _notes.removeWhere((n) => n.deleted);
    await _rebuildAndSaveTagsMapping();
    // S'assurer que toutes les notes non supprimées et non en conflit sont bien marquées comme synchronisées
    for (final note in _notes) {
      if (!note.deleted && note.syncStatus != SyncStatus.conflict) {
        note.syncStatus = SyncStatus.synced;
      }
    }
    notifyListeners();
  }

  Future<void> _syncWithDelay(BuildContext context) async {
    // Affiche l'icône de synchro pendant au moins 1 seconde
    final start = DateTime.now();
    await forceSync(context: context);
    final elapsed = DateTime.now().difference(start);
    if (elapsed.inMilliseconds < 1000) {
      await Future.delayed(Duration(milliseconds: 1000 - elapsed.inMilliseconds));
    }
  }
} 