import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:yaml/yaml.dart' as yaml;

class Note {
  String filePath;
  String title;
  String content;
  List<String> tags;
  DateTime createdAt;
  DateTime updatedAt;

  Note({
    required this.filePath,
    required this.title,
    required this.content,
    this.tags = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : this.createdAt = createdAt ?? DateTime.now(),
        this.updatedAt = updatedAt ?? DateTime.now();

  static Future<Note> fromFile(File file) async {
    final raw = await file.readAsString();
    String content = raw;
    String title = file.uri.pathSegments.last.replaceAll('.md', '');
    List<String> tags = [];
    DateTime? createdAt;
    DateTime? updatedAt;

    if (raw.startsWith('---')) {
      final end = raw.indexOf('---', 3);
      if (end != -1) {
        final frontmatter = raw.substring(3, end).trim();
        final yamlMap = loadYaml(frontmatter) as YamlMap;
        title = yamlMap['title'] ?? title;
        tags = (yamlMap['tags'] as YamlList?)?.cast<String>() ?? [];
        createdAt = yamlMap['createdAt'] != null ? DateTime.tryParse(yamlMap['createdAt'].toString()) : null;
        updatedAt = yamlMap['updatedAt'] != null ? DateTime.tryParse(yamlMap['updatedAt'].toString()) : null;
        content = raw.substring(end + 3).trimLeft();
      }
    }
    return Note(
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
} 