import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notes_provider.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/note.dart';
import 'package:file_selector/file_selector.dart';
import '../utils/snackbar_utils.dart';
import 'sidebar/tag_filter_list.dart';
import 'sidebar/sidebar_action_tile.dart';

class ModernSidebar extends StatefulWidget {
  final Function(List<String>) onTagsSelected;

  const ModernSidebar({Key? key, required this.onTagsSelected}) : super(key: key);

  @override
  State<ModernSidebar> createState() => _ModernSidebarState();
}

class _ModernSidebarState extends State<ModernSidebar> {
  List<String> _selectedTags = [];
  bool _syncing = false;

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
                    const Spacer(),
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
              SidebarActionTile(
                icon: Icons.upload_file,
                text: 'Importer une note',
                onTap: () async {
                  // Ouvre un dialogue natif pour sélectionner un fichier .txt ou .md
                  final typeGroup = XTypeGroup(
                    label: 'Notes',
                    extensions: ['txt', 'md'],
                  );
                  final file = await openFile(acceptedTypeGroups: [typeGroup]);
                  if (file == null) {
                    showAppSnackBar(context, 'Aucun fichier sélectionné.');
                    return;
                  }
                  final content = await file.readAsString();
                  final title = file.name.split('.').first;
                  final notesProvider = Provider.of<NotesProvider>(context, listen: false);
                  await notesProvider.importNote(title, content);
                  showAppSnackBar(context, 'Note importée depuis ${file.name}');
                },
              ),
              SidebarActionTile(
                icon: Icons.folder_open,
                text: 'Changer de dossier',
                onTap: () async {
                  final notesProvider = Provider.of<NotesProvider>(context, listen: false);
                  final result = await notesProvider.moveNotesToNewDirectory(context);
                  if (!result && context.mounted) {
                    showAppSnackBar(context, 'Erreur lors du changement de dossier.');
                  }
                },
              ),
              SidebarActionTile(
                icon: _syncing ? null : Icons.sync,
                text: 'Synchronisation',
                onTap: () async {
                  if (_syncing) return;
                  setState(() => _syncing = true);
                  print('[DEBUG] Bouton synchro cliqué');
                  final notesProvider = Provider.of<NotesProvider>(context, listen: false);
                  await notesProvider.forceSync(context: context);
                  print('[DEBUG] Synchro terminée');
                  if (context.mounted) {
                    showAppSnackBar(context, 'Synchronisation terminée.');
                  }
                  setState(() => _syncing = false);
                },
                enabled: true,
              ),
              SidebarActionTile(
                icon: Icons.refresh,
                text: 'Rafraîchir les notes',
                onTap: () async {
                  final notesProvider = Provider.of<NotesProvider>(context, listen: false);
                  await notesProvider.loadNotes();
                  showAppSnackBar(context, 'Notes rafraîchies depuis le dossier.');
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
                child: TagFilterList(
                  allTags: notesProvider.allTags,
                  selectedTags: _selectedTags,
                  onTagsSelected: (tags) {
                    setState(() { _selectedTags = tags; });
                    if (_selectedTags.isEmpty) notesProvider.loadNotes();
                    widget.onTagsSelected(_selectedTags);
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