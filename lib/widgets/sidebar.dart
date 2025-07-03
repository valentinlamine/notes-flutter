import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notes_provider.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<NotesProvider>(
      builder: (context, notesProvider, child) {
        return Container(
          width: 200,
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Toutes les notes'),
                selected: notesProvider.selectedTag == null,
                onTap: () {
                  notesProvider.clearTagFilter();
                },
              ),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Tags',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: notesProvider.allTags.length,
                  itemBuilder: (context, index) {
                    final tag = notesProvider.allTags[index];
                    return ListTile(
                      leading: const Icon(Icons.tag),
                      title: Text(tag),
                      selected: notesProvider.selectedTag == tag,
                      onTap: () {
                        notesProvider.fetchNotesByTag(tag);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 