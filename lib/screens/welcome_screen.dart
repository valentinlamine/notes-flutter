import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notes_provider.dart';
import 'home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool showLogin = true;
  bool _navigated = false;
  bool showDirectoryWarning = false;

  void switchToSignup() => setState(() => showLogin = false);
  void switchToLogin() => setState(() => showLogin = true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notesProvider = Provider.of<NotesProvider>(context, listen: false);
      notesProvider.onDirectoryAccessError = () {
        if (mounted) {
          setState(() {
            showDirectoryWarning = true;
          });
        }
      };
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = Supabase.instance.client.auth.currentUser;
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    if (!_navigated && user != null && notesProvider.notesDirectory != null && notesProvider.directoryPermissionOk) {
      _navigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final notesProvider = Provider.of<NotesProvider>(context);
    void onSignedIn() => setState(() {});
    final theme = Theme.of(context);

    // 1. Non connecté : login/signup avec branding et message de bienvenue
    if (user == null) {
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
                Text('Bienvenue sur Flutter Notes', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Text('L\'application de prise de notes moderne, rapide et sécurisée pour le desktop. Stockez vos notes en Markdown, gérez vos tags, et synchronisez bientôt dans le cloud !', style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                showLogin
                  ? LoginScreen(onSwitch: switchToSignup, onSignedIn: onSignedIn)
                  : SignupScreen(onSwitch: switchToLogin, onSignedIn: onSignedIn),
              ],
            ),
          ),
        ),
      );
    }

    // 2. Connecté mais pas de dossier OU dossier inaccessible : page de sélection de dossier
    if (notesProvider.notesDirectory == null || !notesProvider.directoryPermissionOk) {
      return Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420, minWidth: 280),
            child: Container(
              padding: const EdgeInsets.all(32),
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
                  if (showDirectoryWarning)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'L\'application n\'a pas pu accéder au dossier de notes sélectionné. Cela peut être dû à un problème de permissions (sandbox macOS) ou à un déplacement/suppression du dossier. Veuillez sélectionner à nouveau le dossier.',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Text('Sélection du dossier de notes', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  Text('Choisissez le dossier où vos notes seront stockées.', style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
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
                        if (result && context.mounted) {
                          notesProvider.resetDirectoryAccessError();
                          setState(() {
                            showDirectoryWarning = false;
                          });
                        } else if (!result && context.mounted) {
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
        ),
      );
    }

    // 3. Tout est ok : redirection automatique
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
} 