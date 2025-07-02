import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notes_provider.dart';
import 'home_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.note_alt_outlined, size: 64, color: theme.primaryColor),
              const SizedBox(height: 24),
              Text(
                'Bienvenue sur Flutter Notes',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Pour commencer, choisissez le dossier où vos notes seront stockées. Vous pourrez changer ce dossier plus tard dans les paramètres.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Consumer<NotesProvider>(
                builder: (context, notesProvider, child) => ElevatedButton.icon(
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Choisir un dossier de notes'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () async {
                    final result = await notesProvider.chooseNotesDirectory();
                    if (!result && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Aucun dossier sélectionné ou erreur.')),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 