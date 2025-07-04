import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as flutter_provider;
import '../services/notes_provider.dart';
import '../widgets/modern_sidebar.dart';
import '../widgets/modern_note_list.dart';
import '../widgets/modern_note_editor.dart';
import '../models/note.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'welcome_screen.dart';
import '../config/supabase_config.dart';

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
      final notesProvider = flutter_provider.Provider.of<NotesProvider>(context, listen: false);
      try {
        await notesProvider.createNote(result, context: context);
        setState(() {}); // Pour rafraîchir la sélection
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossible de créer la note : un fichier avec ce titre existe déjà.')),
          );
        }
      }
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
    final user = Supabase.instance.client.auth.currentUser;
    return Scaffold(
      body: Row(
        children: [
          // Sidebar + bandeau utilisateur
          Container(
            width: 220,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                right: BorderSide(color: theme.dividerColor, width: 1),
              ),
            ),
            child: Column(
              children: [
                Expanded(
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
                if (user != null)
                  _UserProfileBandeau(user: user),
              ],
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
            child: flutter_provider.Consumer<NotesProvider>(
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
            child: flutter_provider.Consumer<NotesProvider>(
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

class _UserProfileBandeau extends StatefulWidget {
  final dynamic user;
  const _UserProfileBandeau({required this.user});

  @override
  State<_UserProfileBandeau> createState() => _UserProfileBandeauState();
}

class _UserProfileBandeauState extends State<_UserProfileBandeau> {
  final GlobalKey _key = GlobalKey();
  OverlayEntry? _overlayEntry;

  void _showMenu() {
    final RenderBox renderBox = _key.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;
    final screenHeight = MediaQuery.of(context).size.height;
    double menuTop = offset.dy + size.height + 8;
    const double menuHeight = 120; // hauteur estimée du menu
    if (menuTop + menuHeight > screenHeight) {
      // Si le menu dépasse le bas de l'écran, affiche-le au-dessus
      menuTop = offset.dy - menuHeight - 8;
    }
    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Zone de clic pour fermer le menu
          Positioned.fill(
            child: GestureDetector(
              onTap: _hideMenu,
              behavior: HitTestBehavior.translucent,
            ),
          ),
          // Le menu lui-même
          Positioned(
            left: offset.dx,
            top: menuTop,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: size.width,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: const Text('Déconnexion'),
                      onTap: () async {
                        _hideMenu();
                        final notesProvider = flutter_provider.Provider.of<NotesProvider>(context, listen: false);
                        await notesProvider.deleteAllNotesAndPrefs();
                        try {
                          await Supabase.instance.client.auth.signOut();
                        } catch (e) {
                          // Silencieux, l'utilisateur est déjà supprimé
                        }
                        notesProvider.clearNotesDirectory();
                        if (mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                            (route) => false,
                          );
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete, color: Colors.red),
                      title: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                      onTap: () async {
                        _hideMenu();
                        final notesProvider = flutter_provider.Provider.of<NotesProvider>(context, listen: false);
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Supprimer le compte'),
                            content: const Text('Êtes-vous sûr de vouloir supprimer votre compte ? Cette action est irréversible.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Annuler'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          final user = Supabase.instance.client.auth.currentUser;
                          if (user == null) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Utilisateur non connecté.')),
                              );
                            }
                            return;
                          }
                          final success = await NotesProvider.deleteAccountAndNotesCloud(user.id);
                          if (success) {
                            await notesProvider.deleteAllNotesAndPrefs();
                            try {
                              await Supabase.instance.client.auth.signOut();
                            } catch (e) {
                              // Silencieux, l'utilisateur est déjà supprimé
                            }
                            notesProvider.clearNotesDirectory();
                            if (mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                                (route) => false,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Compte supprimé avec succès.')),
                              );
                            }
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Erreur lors de la suppression du compte.')),
                              );
                            }
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _hideMenu();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _key,
      onTap: () {
        if (_overlayEntry == null) {
          _showMenu();
        } else {
          _hideMenu();
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.9),
          border: const Border(top: BorderSide(width: 1, color: Colors.black12)),
        ),
        child: Row(
          children: [
            const Icon(Icons.account_circle, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.user.email ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.expand_less, size: 18),
          ],
        ),
      ),
    );
  }
} 