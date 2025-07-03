import 'package:flutter/material.dart';

void showAppSnackBar(BuildContext context, String message, {bool isError = false}) {
  final theme = Theme.of(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: TextStyle(color: theme.colorScheme.onSurface)),
      backgroundColor: isError ? theme.colorScheme.error : theme.colorScheme.surface,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ),
  );
} 