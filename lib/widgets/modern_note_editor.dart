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
  void didUpdateWidget(covariant ModernNoteEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.note?.id != oldWidget.note?.id || widget.isNewNote != oldWidget.isNewNote) {
      _titleController.text = widget.note?.title ?? '';
      _contentController.text = widget.note?.content ?? '';
      _tags = List<String>.from(widget.note?.tags ?? []);
      _tagInputController.clear();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagInputController.dispose();
    super.dispose();
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
      // Ne pas rappeler onNoteSaved ici pour éviter de réinitialiser le champ de titre en cours de frappe
      // L'utilisateur reste en édition sur la nouvelle note
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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header sobre et unifié
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? const Color(0xFF23242A)
                  : const Color(0xFFF3F4F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Titre flottant, padding généreux
                Flexible(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    child: TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'Titre',
                        filled: true,
                        fillColor: theme.brightness == Brightness.dark
                            ? const Color(0xFF23242A)
                            : Colors.white,
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                      ),
                      maxLines: 1,
                      onChanged: (value) {
                        if (value.trim().isNotEmpty) {
                          _saveNote(context);
                        }
                      },
                    ),
                  ),
                ),
                // Tags sobres
                Flexible(
                  flex: 5,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ..._tags.asMap().entries.map((entry) {
                          final tag = entry.value;
                          final pastelColors = [
                            Colors.blue.shade100,
                            Colors.green.shade100,
                            Colors.orange.shade100,
                            Colors.purple.shade100,
                            Colors.pink.shade100,
                            Colors.teal.shade100,
                            Colors.amber.shade100,
                          ];
                          final pastelColorsDark = [
                            Colors.blue.shade700,
                            Colors.green.shade700,
                            Colors.orange.shade700,
                            Colors.purple.shade700,
                            Colors.pink.shade700,
                            Colors.teal.shade700,
                            Colors.amber.shade700,
                          ];
                          final color = theme.brightness == Brightness.dark
                              ? pastelColorsDark[entry.key % pastelColorsDark.length]
                              : pastelColors[entry.key % pastelColors.length];
                          return Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Chip(
                              label: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.brightness == Brightness.dark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                              onDeleted: () {
                                _removeTag(tag);
                                if (_titleController.text.trim().isNotEmpty) {
                                  _saveNote(context);
                                }
                              },
                              backgroundColor: color,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              side: BorderSide.none,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity(horizontal: -2, vertical: -2),
                            ),
                          );
                        }),
                        // Champ d'ajout de tag plus visible
                        Container(
                          width: 70,
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.brightness == Brightness.dark
                                ? const Color(0xFF23242A)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            controller: _tagInputController,
                            decoration: InputDecoration(
                              hintText: 'Tag',
                              filled: true,
                              fillColor: theme.brightness == Brightness.dark
                                  ? const Color(0xFF23242A)
                                  : Colors.white,
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            ),
                            style: const TextStyle(fontSize: 12),
                            onSubmitted: (value) {
                              _addTag(value);
                              if (_titleController.text.trim().isNotEmpty) {
                                _saveNote(context);
                              }
                            },
                            onEditingComplete: () {
                              _addTag(_tagInputController.text);
                              if (_titleController.text.trim().isNotEmpty) {
                                _saveNote(context);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: IconButton(
                        icon: const Icon(Icons.upload_file, size: 20),
                        onPressed: () => _exportNote(context),
                        tooltip: 'Exporter',
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: widget.onClose,
                        tooltip: 'Fermer',
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: IconButton(
                        icon: Icon(_previewMode ? Icons.edit : Icons.preview, size: 20),
                        onPressed: () {
                          setState(() {
                            _previewMode = !_previewMode;
                          });
                        },
                        tooltip: _previewMode ? 'Mode édition' : 'Aperçu Markdown',
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                    if (!widget.isNewNote && widget.note != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          onPressed: () async {
                            final notesProvider = Provider.of<NotesProvider>(context, listen: false);
                            if (widget.note != null && widget.note!.id != null) {
                              await notesProvider.deleteNote(widget.note!.id!);
                              widget.onNoteDeleted();
                            }
                          },
                          tooltip: 'Supprimer',
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Contenu
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              child: _previewMode
                  ? Markdown(
                      data: _contentController.text,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        p: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
                        code: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                        h1: theme.textTheme.titleMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                        h2: theme.textTheme.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                        h3: theme.textTheme.titleMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    )
                  : TextField(
                      controller: _contentController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        hintText: 'Contenu de la note...',
                        filled: true,
                        fillColor: theme.brightness == Brightness.dark
                            ? const Color(0xFF23242A)
                            : const Color(0xFFF8F9FB),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.only(top: 12, left: 12, right: 12, bottom: 0),
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14, height: 1.35),
                      onChanged: (_) {
                        if (_titleController.text.trim().isNotEmpty) {
                          _saveNote(context);
                        }
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
} 