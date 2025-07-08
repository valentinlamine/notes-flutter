import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../services/notes_provider.dart';
import '../models/note.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:markdown/markdown.dart' as md;
import 'note_editor/note_tags_editor.dart';
import 'note_editor/note_editor_actions.dart';
import '../../utils/markdown_to_pdf.dart';
import '../../utils/snackbar_utils.dart';

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
    _previewMode = !widget.isNewNote;
  }

  @override
  void didUpdateWidget(covariant ModernNoteEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.note?.filePath != oldWidget.note?.filePath) {
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
      _autosave();
    }
    _tagInputController.clear();
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
    _autosave();
  }

  void _autosave() async {
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final tags = List<String>.from(_tags);
    if (title.isEmpty || widget.note == null) return;
    final oldTitle = widget.note!.title;
    final updatedNote = Note(
      id: widget.note!.id,
      filePath: widget.note!.filePath,
      title: title,
      content: content,
      tags: tags,
      createdAt: widget.note!.createdAt,
      updatedAt: DateTime.now(),
    );
    if (title != oldTitle) {
      try {
        await notesProvider.saveNote(updatedNote, newTitle: title, context: context);
      } catch (e) {
        showAppSnackBar(context, 'Erreur lors du renommage du fichier : $e');
      }
    } else {
      await notesProvider.saveNote(updatedNote, context: context);
    }
  }

  Future<void> _exportAsPdf() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final pdf = pw.Document();
    final nodes = md.Document().parseLines(content.split('\n'));
    final pdfWidgets = renderMarkdownToPdfWidgets(nodes);
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            ...pdfWidgets,
          ],
        ),
      ),
    );
    String? outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Enregistrer la note en PDF',
      fileName: '$title.pdf',
      allowedExtensions: ['pdf'],
      type: FileType.custom,
    );
    if (outputPath == null) return;
    if (!outputPath.endsWith('.pdf')) outputPath += '.pdf';
    try {
      final file = File(outputPath);
      await file.writeAsBytes(await pdf.save());
      showAppSnackBar(context, 'PDF enregistré : $outputPath');
    } catch (e) {
      showAppSnackBar(context, 'Erreur lors de l\'export PDF : $e');
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
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    child: TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'Titre',
                        filled: true,
                        fillColor: theme.cardColor,
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                      ),
                      maxLines: 1,
                      onChanged: (value) {
                        if (value.trim().isNotEmpty) {
                          _autosave();
                        }
                      },
                    ),
                  ),
                ),
                Flexible(
                  child: NoteEditorActions(
                    previewMode: _previewMode,
                    isNewNote: widget.isNewNote,
                    note: widget.note,
                    onExportPdf: _exportAsPdf,
                    onTogglePreview: () => setState(() => _previewMode = !_previewMode),
                    onDelete: () async {
                      final notesProvider = Provider.of<NotesProvider>(context, listen: false);
                      if (widget.note != null) {
                        await notesProvider.deleteNote(widget.note!, context: context);
                        widget.onNoteDeleted();
                      }
                    },
                    onClose: widget.onClose,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: NoteTagsEditor(
              tags: _tags,
              onAddTag: (tag) {
                setState(() { _tags.add(tag); });
                _autosave();
              },
              onRemoveTag: (tag) {
                setState(() { _tags.remove(tag); });
                _autosave();
              },
            ),
          ),
          const SizedBox(height: 8),
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
                        fillColor: theme.colorScheme.surface,
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
                          _autosave();
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