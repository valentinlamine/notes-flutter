import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../services/notes_provider.dart';
import '../models/note.dart';
import '../services/export_service.dart';

class ModernNoteEditor extends StatefulWidget {
  final Note? note;
  final bool isNewNote;
  final Function(Note) onNoteSaved;
  final VoidCallback onNoteDeleted;
  final VoidCallback onClose;

  const ModernNoteEditor({
    Key? key,
    this.note,
    this.isNewNote = false,
    required this.onNoteSaved,
    required this.onNoteDeleted,
    required this.onClose,
  }) : super(key: key);

  @override
  State<ModernNoteEditor> createState() => _ModernNoteEditorState();
}

class _ModernNoteEditorState extends State<ModernNoteEditor> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _tagInputController;
  List<String> _tags = [];
  bool _previewMode = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _tags = List<String>.from(widget.note?.tags ?? []);
    _tagInputController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ModernNoteEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si on passe d'une note à une autre ou d'une note à nouvelle note, on réinitialise les champs
    if (widget.note?.id != oldWidget.note?.id || widget.isNewNote != oldWidget.isNewNote) {
      _titleController.text = widget.note?.title ?? '';
      _contentController.text = widget.note?.content ?? '';
      _tags = List<String>.from(widget.note?.tags ?? []);
      _tagInputController.clear();
    }
  }

  void _addTag(String tag) {
    final cleanTag = tag.trim();
    if (cleanTag.isNotEmpty && !_tags.contains(cleanTag)) {
      setState(() {
        _tags.add(cleanTag);
      });
    }
    _tagInputController.clear();
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _saveNote(BuildContext context) async {
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final tags = List<String>.from(_tags);

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le titre ne peut pas être vide')),
      );
      return;
    }

    if (widget.isNewNote) {
      final note = Note(
        title: title,
        content: content,
        tags: tags,
      );
      await notesProvider.addNote(note);
      widget.onNoteSaved(note);
    } else if (widget.note != null) {
      final updatedNote = Note(
        id: widget.note!.id,
        title: title,
        content: content,
        tags: tags,
        createdAt: widget.note!.createdAt,
        updatedAt: DateTime.now(),
      );
      await notesProvider.updateNote(updatedNote);
      widget.onNoteSaved(updatedNote);
    }
  }

  Future<void> _exportNote(BuildContext context) async {
    final exportService = ExportService();
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le titre et le contenu ne peuvent pas être vides')),
      );
      return;
    }
    final format = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Exporter la note'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'txt'),
            child: const Text('Format texte (.txt)'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'md'),
            child: const Text('Format Markdown (.md)'),
          ),
        ],
      ),
    );
    if (format != null) {
      await exportService.exportToFile(title, content, format);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Note exportée au format .$format')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade400, width: 1.2),
    );
    final focusBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.deepPurple.shade200, width: 2),
    );
    final fillColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.grey[900]
        : Colors.grey[100];
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Titre',
              filled: true,
              fillColor: fillColor,
              border: border,
              focusedBorder: focusBorder,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          // Tag input chips
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 4,
              runSpacing: 0,
              children: [
                ..._tags.map((tag) => Chip(
                      label: Text(tag),
                      onDeleted: () => _removeTag(tag),
                      backgroundColor: Colors.deepPurple.shade50,
                      labelStyle: const TextStyle(fontSize: 13),
                    )),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _tagInputController,
                    decoration: InputDecoration(
                      hintText: 'Ajouter un tag',
                      border: InputBorder.none,
                      filled: true,
                      fillColor: fillColor,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    ),
                    onSubmitted: _addTag,
                    onEditingComplete: () {
                      _addTag(_tagInputController.text);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _previewMode
                ? Card(
                    color: fillColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Markdown(
                        data: _contentController.text,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  )
                : TextField(
                    controller: _contentController,
                    maxLines: null,
                    expands: true,
                    decoration: InputDecoration(
                      labelText: 'Contenu',
                      alignLabelWithHint: true,
                      filled: true,
                      fillColor: fillColor,
                      border: border,
                      focusedBorder: focusBorder,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    style: const TextStyle(fontSize: 15),
                  ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.upload_file),
                onPressed: () => _exportNote(context),
                tooltip: 'Exporter la note',
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: widget.onClose,
                tooltip: 'Fermer',
              ),
              IconButton(
                icon: Icon(_previewMode ? Icons.edit : Icons.preview),
                onPressed: () {
                  setState(() {
                    _previewMode = !_previewMode;
                  });
                },
                tooltip: _previewMode ? 'Mode édition' : 'Aperçu Markdown',
              ),
              if (!widget.isNewNote && widget.note != null)
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
                    if (widget.note != null && widget.note!.id != null) {
                      await notesProvider.deleteNote(widget.note!.id!);
                      widget.onNoteDeleted();
                    }
                  },
                  tooltip: 'Supprimer la note',
                ),
              ElevatedButton(
                onPressed: () => _saveNote(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple.shade400,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
                child: const Text('Enregistrer'),
              ),
            ],
          )
        ],
      ),
    );
  }
} 