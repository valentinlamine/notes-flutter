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
        await notesProvider.saveNote(updatedNote, newTitle: title);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors du renommage du fichier : $e')),
          );
        }
      }
    } else {
      await notesProvider.saveNote(updatedNote);
    }
  }

  Future<void> _exportAsPdf() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final pdf = pw.Document();
    // Parse le markdown en AST
    final nodes = md.Document().parseLines(content.split('\n'));
    // Fonction récursive pour convertir AST markdown -> widgets PDF
    List<pw.Widget> _renderMarkdown(List<md.Node> nodes) {
      List<pw.Widget> widgets = [];
      for (final node in nodes) {
        if (node is md.Element) {
          switch (node.tag) {
            case 'h1':
              widgets.add(pw.Text(node.textContent, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)));
              break;
            case 'h2':
              widgets.add(pw.Text(node.textContent, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)));
              break;
            case 'h3':
              widgets.add(pw.Text(node.textContent, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)));
              break;
            case 'ul':
              widgets.add(
                pw.Bullet(
                  text: node.children!.map((li) => li.textContent).join('\n'),
                  style: pw.TextStyle(fontSize: 14),
                ),
              );
              break;
            case 'ol':
              for (int i = 0; i < node.children!.length; i++) {
                widgets.add(pw.Row(children: [
                  pw.Text('${i + 1}. ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(node.children![i].textContent, style: pw.TextStyle(fontSize: 14)),
                ]));
              }
              break;
            case 'blockquote':
              widgets.add(
                pw.Container(
                  decoration: pw.BoxDecoration(border: pw.Border(left: pw.BorderSide(width: 2))),
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: pw.Text(node.textContent, style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 14)),
                ),
              );
              break;
            case 'pre':
              widgets.add(
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  margin: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Text(node.textContent, style: pw.TextStyle(font: pw.Font.courier(), fontSize: 12)),
                ),
              );
              break;
            case 'p':
              widgets.add(pw.Text(node.textContent, style: pw.TextStyle(fontSize: 14)));
              break;
            default:
              widgets.addAll(_renderMarkdown(node.children ?? []));
          }
        } else if (node is md.Text) {
          widgets.add(pw.Text(node.text, style: pw.TextStyle(fontSize: 14)));
        }
      }
      return widgets;
    }
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            ..._renderMarkdown(nodes),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF enregistré : $outputPath')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'export PDF : $e')),
        );
      }
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
                          _autosave();
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
                                  _autosave();
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
                                _autosave();
                              }
                            },
                            onEditingComplete: () {
                              _addTag(_tagInputController.text);
                              if (_titleController.text.trim().isNotEmpty) {
                                _autosave();
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
                        icon: const Icon(Icons.folder_open, size: 20),
                        onPressed: () {
                          // provider.revealInFinder(widget.note!); // désactivé en local
                        },
                        tooltip: 'Ouvrir dans le Finder',
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: IconButton(
                        icon: Icon(_previewMode ? Icons.edit : Icons.visibility, size: 20),
                        onPressed: () {
                          setState(() {
                            _previewMode = !_previewMode;
                          });
                        },
                        tooltip: _previewMode ? 'Passer en mode édition' : 'Passer en mode aperçu',
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
                            if (widget.note != null) {
                              await notesProvider.deleteNote(widget.note!);
                              widget.onNoteDeleted();
                            }
                          },
                          tooltip: 'Supprimer',
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: IconButton(
                        icon: const Icon(Icons.picture_as_pdf, size: 20),
                        onPressed: _exportAsPdf,
                        tooltip: 'Exporter en PDF',
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                    // Bouton Fermer à droite
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: widget.onClose,
                        tooltip: 'Fermer',
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