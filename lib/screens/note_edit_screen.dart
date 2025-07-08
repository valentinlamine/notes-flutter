import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart' as flutter_provider;
import '../models/note.dart';
import '../services/notes_provider.dart';
import '../services/export_service.dart';

class NoteEditScreen extends StatefulWidget {
  final Note? note;

  const NoteEditScreen({Key? key, this.note}) : super(key: key);

  @override
  _NoteEditScreenState createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _tagsController;
  bool _previewMode = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _tagsController = TextEditingController(
        text: widget.note?.tags.join(', ') ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  List<String> _parseTags(String tagsText) {
    return tagsText
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
  }

  Future<void> _saveNote(BuildContext context) async {
    final notesProvider = flutter_provider.Provider.of<NotesProvider>(context, listen: false);
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final tags = _parseTags(_tagsController.text);

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le titre ne peut pas être vide')),
      );
      return;
    }

    if (widget.note == null) {
      final note = Note(
        title: title,
        content: content,
        tags: tags,
      );
      try {
        await notesProvider.createNote(title, context: context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible de créer la note : un fichier avec ce titre existe déjà.')),
        );
        return;
      }
    } else {
      final updatedNote = Note(
        id: widget.note!.id,
        title: title,
        content: content,
        tags: tags,
        createdAt: widget.note!.createdAt,
        updatedAt: DateTime.now(),
      );
      await notesProvider.saveNote(updatedNote, context: context);
    }

    Navigator.pop(context);
  }

  Future<void> _deleteNote(BuildContext context) async {
    if (widget.note == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la note'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette note ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await flutter_provider.Provider.of<NotesProvider>(context, listen: false)
          .deleteNote(widget.note!, context: context);
      Navigator.pop(context);
    }
  }

  Future<void> _exportNote() async {
    final exportService = ExportService();
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le titre et le contenu ne peuvent pas être vides')),
      );
      return;
    }

    try {
      await exportService.exportToFile(title, content, _previewMode ? 'md' : 'txt');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note exportée avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'exportation: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'Nouvelle note' : 'Modifier la note'),
        actions: [
          IconButton(
            icon: Icon(_previewMode ? Icons.edit : Icons.preview),
            onPressed: () {
              setState(() {
                _previewMode = !_previewMode;
              });
            },
            tooltip: _previewMode ? 'Mode édition' : 'Aperçu Markdown',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportNote,
            tooltip: 'Exporter la note',
          ),
          if (widget.note != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteNote(context),
              tooltip: 'Supprimer la note',
            ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _saveNote(context),
            tooltip: 'Enregistrer la note',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre',
                border: OutlineInputBorder(),
              ),
              enabled: !_previewMode,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags (séparés par des virgules)',
                border: OutlineInputBorder(),
                hintText: 'travail, important, todo, ...',
              ),
              enabled: !_previewMode,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _previewMode
                  ? Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Markdown(
                          data: _contentController.text,
                          selectable: true,
                        ),
                      ),
                    )
                  : TextField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        labelText: 'Contenu (support Markdown)',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                    ),
            ),
          ],
        ),
      ),
    );
  }
} 