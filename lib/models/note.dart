import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:yaml/yaml.dart' as yaml;
import 'package:uuid/uuid.dart';

// Enum pour le statut de synchronisation
enum SyncStatus { notSynced, syncing, synced, conflict }

class Note {
  String id;
  String filePath;
  String title;
  String content;
  List<String> tags;
  DateTime createdAt;
  DateTime updatedAt;
  // Champs pour la synchro cloud
  String? remoteId;
  SyncStatus syncStatus;
  DateTime? lastSyncedAt;
  bool deleted;

  Note({
    String? id,
    required this.filePath,
    required this.title,
    required this.content,
    this.tags = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
    this.remoteId,
    this.syncStatus = SyncStatus.notSynced,
    this.lastSyncedAt,
    this.deleted = false,
  })  : this.id = id ?? const Uuid().v4(),
        this.createdAt = createdAt ?? DateTime.now(),
        this.updatedAt = updatedAt ?? DateTime.now();

  static Future<Note> fromFile(File file) async {
    final raw = await file.readAsString();
    String content = raw;
    String title = file.uri.pathSegments.last.replaceAll('.md', '');
    List<String> tags = [];
    DateTime? createdAt;
    DateTime? updatedAt;
    String? id;
    if (raw.startsWith('---')) {
      final end = raw.indexOf('---', 3);
      if (end != -1) {
        final frontmatter = raw.substring(3, end).trim();
        final yamlMap = loadYaml(frontmatter) as YamlMap;
        id = yamlMap['id'] as String?;
        title = yamlMap['title'] ?? title;
        tags = (yamlMap['tags'] as YamlList?)?.cast<String>() ?? [];
        createdAt = yamlMap['createdAt'] != null ? DateTime.tryParse(yamlMap['createdAt'].toString()) : null;
        updatedAt = yamlMap['updatedAt'] != null ? DateTime.tryParse(yamlMap['updatedAt'].toString()) : null;
        content = raw.substring(end + 3).trimLeft();
      }
    }
    return Note(
      id: id,
      filePath: file.path,
      title: title,
      content: content,
      tags: tags,
      createdAt: createdAt ?? await file.lastModified(),
      updatedAt: updatedAt ?? await file.lastModified(),
    );
  }

  Future<void> saveToFile() async {
    final file = File(filePath);
    final buffer = StringBuffer();
    buffer.writeln('---');
    buffer.writeln('id: $id');
    buffer.writeln('title: ${title.replaceAll(':', ' ')}');
    buffer.writeln('tags:');
    for (final tag in tags) {
      buffer.writeln('  - ${tag.replaceAll('-', ' ')}');
    }
    buffer.writeln('createdAt: ${createdAt.toIso8601String()}');
    buffer.writeln('updatedAt: ${DateTime.now().toIso8601String()}');
    buffer.writeln('---');
    buffer.writeln(content.trimLeft());
    await file.writeAsString(buffer.toString());
  }

  Future<void> deleteFile() async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  // Conversion Map <-> Note pour Supabase
  factory Note.fromSupabase(Map<String, dynamic> map, {String? localFilePath}) {
    return Note(
      id: map['id'] as String? ?? const Uuid().v4(),
      filePath: localFilePath ?? '',
      remoteId: map['id'] as String?,
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      tags: (map['tags'] as List?)?.cast<String>() ?? [],
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
      syncStatus: SyncStatus.synced,
      lastSyncedAt: DateTime.tryParse(map['updated_at'] ?? ''),
      deleted: map['deleted'] == true,
    );
  }

  Map<String, dynamic> toSupabaseMap(String userId) {
    final map = {
      'id': id,
      'user_id': userId,
      'title': title,
      'content': content,
      'tags': tags,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted': deleted,
    };
    return map;
  }
} 