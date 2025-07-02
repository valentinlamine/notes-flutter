import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notes_provider.dart';

class ModernSidebar extends StatelessWidget {
  final Function(String?) onTagSelected;

  const ModernSidebar({Key? key, required this.onTagSelected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<NotesProvider>(
      builder: (context, notesProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.note_outlined,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Flutter Notes',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Toutes les notes'),
              selected: notesProvider.selectedTag == null,
              onTap: () {
                notesProvider.clearTagFilter();
                onTagSelected(null);
              },
            ),
            ListTile(
              leading: const Icon(Icons.bug_report),
              title: const Text('Debug DB'),
              onTap: () async {
                await notesProvider.debugDatabase();
                notesProvider.debugPrintNotes();
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'TAGS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: notesProvider.allTags.length,
                itemBuilder: (context, index) {
                  final tag = notesProvider.allTags[index];
                  return ListTile(
                    leading: const Icon(Icons.tag, size: 16),
                    title: Text(tag),
                    selected: notesProvider.selectedTag == tag,
                    dense: true,
                    onTap: () {
                      notesProvider.fetchNotesByTag(tag);
                      onTagSelected(tag);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
} 