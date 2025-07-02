import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: Color(0xFF7C5CFA), // Accent violet discret
        secondary: Color(0xFFB3B3B3),
        background: Color(0xFFF8F9FB),
        surface: Color(0xFFFFFFFF),
        onPrimary: Colors.white,
        onSecondary: Color(0xFF23242A),
        onBackground: Color(0xFF23242A),
        onSurface: Color(0xFF23242A),
      ),
      scaffoldBackgroundColor: Color(0xFFF8F9FB),
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFFF8F9FB),
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF7C5CFA)),
        titleTextStyle: TextStyle(
          color: Color(0xFF23242A),
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontSize: 15, color: Color(0xFF23242A)),
        titleMedium: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: Color(0xFF23242A)),
        titleLarge: TextStyle(fontWeight: FontWeight.w700, fontSize: 22, color: Color(0xFF23242A)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFFF3F4F7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: Color(0xFFE0E1E6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: Color(0xFF7C5CFA), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: Color(0xFFE0E1E6)),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Color(0xFFF0F1F5),
        labelStyle: TextStyle(color: Color(0xFF23242A)),
        selectedColor: Color(0xFF7C5CFA).withOpacity(0.12),
        secondarySelectedColor: Color(0xFF7C5CFA).withOpacity(0.12),
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerColor: Color(0xFFE0E1E6),
      iconTheme: IconThemeData(color: Color(0xFF7C5CFA)),
      buttonTheme: ButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        buttonColor: Color(0xFF7C5CFA),
        textTheme: ButtonTextTheme.primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF7C5CFA),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          textStyle: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Color(0xFF7C5CFA),
          textStyle: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: Color(0xFF7C5CFA),
        secondary: Color(0xFFB3B3B3),
        background: Color(0xFF20212B),
        surface: Color(0xFF23242A),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onBackground: Color(0xFFF8F9FB),
        onSurface: Color(0xFFF8F9FB),
      ),
      scaffoldBackgroundColor: Color(0xFF20212B),
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF20212B),
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF7C5CFA)),
        titleTextStyle: TextStyle(
          color: Color(0xFFF8F9FB),
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontSize: 15, color: Color(0xFFF8F9FB)),
        titleMedium: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: Color(0xFFF8F9FB)),
        titleLarge: TextStyle(fontWeight: FontWeight.w700, fontSize: 22, color: Color(0xFFF8F9FB)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF23242A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: Color(0xFF35363C)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: Color(0xFF7C5CFA), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: Color(0xFF35363C)),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      cardTheme: CardThemeData(
        color: Color(0xFF23242A),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Color(0xFF35363C),
        labelStyle: TextStyle(color: Color(0xFFF8F9FB)),
        selectedColor: Color(0xFF7C5CFA).withOpacity(0.18),
        secondarySelectedColor: Color(0xFF7C5CFA).withOpacity(0.18),
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerColor: Color(0xFF35363C),
      iconTheme: IconThemeData(color: Color(0xFF7C5CFA)),
      buttonTheme: ButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        buttonColor: Color(0xFF7C5CFA),
        textTheme: ButtonTextTheme.primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF7C5CFA),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          textStyle: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Color(0xFF7C5CFA),
          textStyle: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
} 