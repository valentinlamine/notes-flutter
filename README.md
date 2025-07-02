# myflutterapp

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

# Flutter Notes Desktop

## Installation et compilation

1. **Installer les dépendances**

```bash
flutter pub get
```

2. **Exécuter l'application en mode développement**

```bash
flutter run -d macos
```

3. **Construire l'application pour macOS**

```bash
flutter build macos
```

4. **Créer un fichier DMG (optionnel)**

Installer l'utilitaire `create-dmg` via Homebrew :

```bash
brew install create-dmg
```

Créer le DMG :

```bash
create-dmg \
  --volname "Flutter Notes" \
  --window-pos 200 120 \
  --window-size 800 400 \
  --icon-size 100 \
  --icon "flutter_notes_app.app" 200 190 \
  --hide-extension "flutter_notes_app.app" \
  --app-drop-link 600 185 \
  "FlutterNotes.dmg" \
  "build/macos/Build/Products/Release/flutter_notes_app.app"
```

## Structure du projet

```
lib/
  config/           # Thèmes, routes, constantes
  models/           # Modèles de données
  services/         # Services (stockage, export)
  screens/          # Pages de l'application
  widgets/          # Composants réutilisables
  utils/            # Fonctions utilitaires
assets/             # Images, polices, etc.
```

## Fonctionnalités principales
- Prise de notes avec support Markdown
- Organisation par tags
- Recherche et filtrage
- Export de notes (txt/md)
- Thème clair/sombre
- Stockage local SQLite

## Fonctionnalités avancées (à venir)
- Synchronisation cloud (Supabase)
- Import de notes
- Raccourcis clavier
- Sauvegarde automatique
- Tri avancé
