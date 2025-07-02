import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notes_provider.dart';
import '../widgets/modern_sidebar.dart';
import '../widgets/modern_note_list.dart';
import '../widgets/modern_note_editor.dart';
import '../models/note.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Note? _selectedNote;
  bool _isEditing = false;
  List<String> _selectedTags = [];

  void _onNoteSelected(Note note) {
    setState(() {
      _selectedNote = note;
      _isEditing = false;
    });
  }

  Future<void> _onNewNote() async {
    final titleController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouveau titre de note'),
        content: TextField(
          controller: titleController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Titre de la note',
          ),
          onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              final value = titleController.text.trim();
              if (value.isNotEmpty) {
                Navigator.of(context).pop(value);
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      final notesProvider = Provider.of<NotesProvider>(context, listen: false);
      await notesProvider.createNote(result);
      setState(() {}); // Pour rafraîchir la sélection
    }
  }

  void _onNoteSaved(Note note) {
    setState(() {
      _selectedNote = note;
      _isEditing = false;
    });
  }

  void _onNoteDeleted() {
    setState(() {
      _selectedNote = null;
      _isEditing = false;
    });
  }

  void _onCloseEditor() {
    setState(() {
      _selectedNote = null;
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 220,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                right: BorderSide(color: theme.dividerColor, width: 1),
              ),
            ),
            child: ModernSidebar(
              onTagsSelected: (tags) {
                setState(() {
                  _selectedNote = null;
                  _isEditing = false;
                  _selectedTags = tags;
                });
              },
            ),
          ),
          // Liste des notes
          Container(
            width: 300,
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(
                right: BorderSide(color: theme.dividerColor, width: 1),
              ),
            ),
            child: Consumer<NotesProvider>(
              builder: (context, notesProvider, child) => ModernNoteList(
                notes: notesProvider.notesForTags(_selectedTags),
                selectedNote: notesProvider.selectedNote,
                onNoteSelected: notesProvider.selectNote,
                onNewNote: _onNewNote,
              ),
            ),
          ),
          // Éditeur/Prévisualisation
          Expanded(
            child: Consumer<NotesProvider>(
              builder: (context, notesProvider, child) => notesProvider.selectedNote != null
                  ? ModernNoteEditor(
                      note: notesProvider.selectedNote!,
                      onNoteSaved: (note) => notesProvider.saveNote(note),
                      onNoteDeleted: () => notesProvider.deleteNote(notesProvider.selectedNote!),
                      onClose: () => notesProvider.selectNote(null),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.note_add_outlined, size: 64, color: theme.colorScheme.secondary),
                          const SizedBox(height: 16),
                          Text(
                            'Sélectionnez une note ou créez-en une nouvelle',
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
} 