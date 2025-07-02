import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notes_provider.dart';
import '../models/note.dart';

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
                subtitle: Text(
                  note.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                selected: selectedNote?.filePath == note.filePath,
                onTap: () => onNoteSelected(note),
              );
            },
          ),
        ),
      ],
    );
  }
} 