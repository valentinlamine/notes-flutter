import 'dart:io';

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
    final content = await file.readAsString();
    final title = file.uri.pathSegments.last.replaceAll('.md', '');
    // Optionnel : extraire tags depuis le contenu ou le nom du fichier
    return Note(
      filePath: file.path,
      title: title,
      content: content,
      tags: [],
      createdAt: await file.lastModified(),
      updatedAt: await file.lastModified(),
    );
  }

  Future<void> saveToFile() async {
    final file = File(filePath);
    await file.writeAsString(content);
  }

  Future<void> deleteFile() async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
} 