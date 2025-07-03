import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignupScreen extends StatefulWidget {
  final VoidCallback onSwitch;
  final VoidCallback onSignedIn;
  const SignupScreen({Key? key, required this.onSwitch, required this.onSignedIn}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    setState(() { _isLoading = true; _error = null; });
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    try {
      final res = await Supabase.instance.client.auth.signUp(email: email, password: password);
      if (res.user == null) {
        setState(() { _error = "Erreur lors de la création du compte."; });
      } else {
        widget.onSignedIn();
      }
    } on AuthException catch (e) {
      setState(() { _error = e.message; });
    } catch (e) {
      setState(() { _error = 'Erreur inconnue : $e'; });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, minWidth: 280),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.person_add_alt_1, size: 48, color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text('Inscription', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Créez un compte pour sauvegarder et synchroniser vos notes.', style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Mot de passe', border: OutlineInputBorder()),
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(_error!, style: const TextStyle(color: Colors.red)),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signup,
                      child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Inscription'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: widget.onSwitch,
                    child: const Text('Déjà un compte ? Se connecter'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 