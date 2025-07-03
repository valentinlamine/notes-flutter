import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notes_provider.dart';
import '../models/note.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ModernNoteList extends StatelessWidget {
  final List<Note> notes;
  final Note? selectedNote;
  final Function(Note) onNoteSelected;
  final VoidCallback onNewNote;

  const ModernNoteList({
    Key? key,
    required this.notes,
    required this.selectedNote,
    required this.onNoteSelected,
    required this.onNewNote,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Notes', style: Theme.of(context).textTheme.titleMedium),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: onNewNote,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return ListTile(
                title: Text(note.title),
                subtitle: SizedBox(
                  height: 22, // hauteur d'une ligne
                  child: MarkdownBody(
                    data: note.content.split('\n').first,
                    styleSheet: MarkdownStyleSheet(
                      p: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13, height: 1.2),
                      h1: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 15),
                      h2: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
                      h3: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    softLineBreak: true,
                    shrinkWrap: true,
                  ),
                ),
                trailing: _buildSyncStatusIcon(context, note.syncStatus),
                selected: selectedNote?.filePath == note.filePath,
                onTap: () => onNoteSelected(note),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSyncStatusIcon(BuildContext context, SyncStatus status) {
    late Icon icon;
    late String message;

    switch (status) {
      case SyncStatus.synced:
        icon = Icon(Icons.cloud_done, color: Colors.greenAccent.shade400, size: 18);
        message = 'Synchronisé';
        break;
      case SyncStatus.syncing:
        icon = Icon(Icons.cloud_upload, color: Colors.orangeAccent.shade200, size: 18);
        message = 'Synchronisation en cours...';
        break;
      case SyncStatus.conflict:
        icon = Icon(Icons.error, color: Colors.redAccent.shade200, size: 18);
        message = 'Conflit de synchronisation';
        break;
      case SyncStatus.notSynced:
      default:
        icon = Icon(Icons.cloud_queue, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), size: 18);
        message = 'Non synchronisé';
        break;
    }
    return Tooltip(message: message, child: icon);
  }
} 