import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../services/notes_provider.dart';
import '../models/note.dart';

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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Titre'),
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
                    )),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _tagInputController,
                    decoration: const InputDecoration(
                      hintText: 'Ajouter un tag',
                      border: InputBorder.none,
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
                    maxLines: null,
                    expands: true,
                    decoration: const InputDecoration(
                      labelText: 'Contenu',
                      alignLabelWithHint: true,
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
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
                child: const Text('Enregistrer'),
              ),
            ],
          )
        ],
      ),
    );
  }
} 