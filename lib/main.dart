import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/notes_provider.dart';
import 'config/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => NotesProvider(),
      child: MaterialApp(
        title: 'Flutter Notes',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        home: Consumer<NotesProvider>(
          builder: (context, notesProvider, _) {
            if (notesProvider.notesDirectory == null) {
              return const WelcomeScreen();
            } else {
              return const HomeScreen();
            }
          },
        ),
      ),
    );
  }
}
