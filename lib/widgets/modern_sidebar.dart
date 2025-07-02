import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notes_provider.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/note.dart';
import 'package:file_selector/file_selector.dart';

class ModernSidebar extends StatefulWidget {
  final Function(List<String>) onTagsSelected;

  const ModernSidebar({Key? key, required this.onTagsSelected}) : super(key: key);

  @override
  State<ModernSidebar> createState() => _ModernSidebarState();
}

class _ModernSidebarState extends State<ModernSidebar> {
  List<String> _selectedTags = [];

  @override
  Widget build(BuildContext context) {
    return Consumer<NotesProvider>(
      builder: (context, notesProvider, child) {
        final theme = Theme.of(context);
        return Container(
          color: theme.brightness == Brightness.dark
              ? const Color(0xFF23242A)
              : const Color(0xFFF3F4F7),
          child: Column(
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
                selected: _selectedTags.isEmpty,
                onTap: () {
                  setState(() {
                    _selectedTags.clear();
                  });
                  notesProvider.loadNotes();
                  widget.onTagsSelected(_selectedTags);
                },
              ),
              ListTile(
                leading: const Icon(Icons.file_upload),
                title: const Text('Importer une note'),
                onTap: () async {
                  // Ouvre un dialogue natif pour sélectionner un fichier .txt ou .md
                  final typeGroup = XTypeGroup(
                    label: 'Notes',
                    extensions: ['txt', 'md'],
                  );
                  final file = await openFile(acceptedTypeGroups: [typeGroup]);
                  if (file == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Aucun fichier sélectionné.')),
                    );
                    return;
                  }
                  final content = await file.readAsString();
                  final title = file.name.split('.').first;
                  final notesProvider = Provider.of<NotesProvider>(context, listen: false);
                  final filePath = notesProvider.notesDirectory != null ? '${notesProvider.notesDirectory}/$title.md' : '';
                  await notesProvider.createNote(title);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Note importée depuis ${file.name}')),
                  );
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
                    return CheckboxListTile(
                      value: _selectedTags.contains(tag),
                      title: Text(tag),
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            _selectedTags.add(tag);
                          } else {
                            _selectedTags.remove(tag);
                          }
                        });
                        if (_selectedTags.isEmpty) {
                          notesProvider.loadNotes();
                        } else {
                          notesProvider.filterNotesByTags(_selectedTags);
                        }
                        widget.onTagsSelected(_selectedTags);
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