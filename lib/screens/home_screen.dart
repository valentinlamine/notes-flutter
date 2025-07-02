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

  void _onNoteSelected(Note note) {
    setState(() {
      _selectedNote = note;
      _isEditing = false;
    });
  }

  void _onNewNote() {
    setState(() {
      _selectedNote = null;
      _isEditing = true;
    });
  }

  void _onCloseEditor() {
    setState(() {
      _selectedNote = null;
      _isEditing = false;
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar - 250px fixe
          Container(
            width: 250,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: ModernSidebar(
              onTagsSelected: (tags) {
                setState(() {
                  // La logique de filtrage est déjà gérée dans le provider
                  // On peut éventuellement réinitialiser la sélection de note ici si besoin
                  _selectedNote = null;
                  _isEditing = false;
                });
              },
            ),
          ),
          // Liste des notes - 300px fixe
          Container(
            width: 300,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: ModernNoteList(
              selectedNote: _selectedNote,
              onNoteSelected: _onNoteSelected,
              onNewNote: _onNewNote,
            ),
          ),
          // Éditeur/Prévisualisation - Flexible
          Expanded(
            child: _selectedNote != null || _isEditing
                ? ModernNoteEditor(
                    note: _selectedNote,
                    isNewNote: _selectedNote == null && _isEditing,
                    onNoteSaved: _onNoteSaved,
                    onNoteDeleted: _onNoteDeleted,
                    onClose: _onCloseEditor,
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.note_add_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Sélectionnez une note ou créez-en une nouvelle',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
} 