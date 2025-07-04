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
              final isSelected = selectedNote?.filePath == note.filePath;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => onNoteSelected(note),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary.withOpacity(0.08)
                            : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          width: 2, // Fixe l'épaisseur pour éviter le "jump"
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.10),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          else
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        // Fixe la hauteur minimale pour toutes les cards
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 80),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      note.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                        color: isSelected
                                            ? Theme.of(context).colorScheme.primary
                                            : Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildSyncStatusIcon(context, note.syncStatus),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Container(
                                constraints: const BoxConstraints(maxHeight: 54),
                                child: ClipRect(
                                  child: MarkdownBody(
                                    data: note.content.split('\n').take(3).join('\n'),
                                    styleSheet: MarkdownStyleSheet(
                                      p: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontSize: 13,
                                        height: 1.2,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                      ),
                                      h1: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 15),
                                      h2: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
                                      h3: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    softLineBreak: true,
                                    shrinkWrap: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
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