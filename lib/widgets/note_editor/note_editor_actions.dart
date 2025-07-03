import 'package:flutter/material.dart';
import '../../models/note.dart';
import 'package:provider/provider.dart';
import '../../services/notes_provider.dart';

class NoteEditorActions extends StatelessWidget {
  final bool previewMode;
  final bool isNewNote;
  final Note? note;
  final VoidCallback onExportPdf;
  final VoidCallback onTogglePreview;
  final VoidCallback onDelete;
  final VoidCallback onClose;

  const NoteEditorActions({
    Key? key,
    required this.previewMode,
    required this.isNewNote,
    required this.note,
    required this.onExportPdf,
    required this.onTogglePreview,
    required this.onDelete,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: IconButton(
            icon: const Icon(Icons.picture_as_pdf, size: 20),
            onPressed: onExportPdf,
            tooltip: 'Exporter en PDF',
            padding: const EdgeInsets.all(8),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: IconButton(
            icon: Icon(previewMode ? Icons.edit : Icons.visibility, size: 20),
            onPressed: onTogglePreview,
            tooltip: previewMode ? 'Passer en mode édition' : 'Passer en mode aperçu',
            padding: const EdgeInsets.all(8),
          ),
        ),
        if (!isNewNote && note != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: IconButton(
              icon: const Icon(Icons.folder_open, size: 20),
              onPressed: () async {
                final provider = Provider.of<NotesProvider>(context, listen: false);
                await provider.revealInFinder(note!);
              },
              tooltip: 'Afficher dans le Finder',
              padding: const EdgeInsets.all(8),
            ),
          ),
        if (!isNewNote && note != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: IconButton(
              icon: const Icon(Icons.delete, size: 20),
              onPressed: onDelete,
              tooltip: 'Supprimer',
              padding: const EdgeInsets.all(8),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: onClose,
            tooltip: 'Fermer',
            padding: const EdgeInsets.all(8),
          ),
        ),
      ],
    );
  }
} 