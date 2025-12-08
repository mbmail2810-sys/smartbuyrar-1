import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryGreen = Color(0xFF00B200);

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryGreen,
      brightness: Brightness.light,
    ).copyWith(
      primary: primaryGreen,
      surface: Colors.green[50],
    );

    return ThemeData(
      fontFamily: 'NotoSans',
      useMaterial3: true,
      brightness: Brightness.light,
      canvasColor: Colors.green[50],
      colorScheme: colorScheme,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: primaryGreen,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButtonTheme:
          const FloatingActionButtonThemeData(shape: CircleBorder()),
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryGreen,
      brightness: Brightness.dark,
    ).copyWith(
      primary: primaryGreen,
    );

    return ThemeData(
      fontFamily: 'NotoSans',
      useMaterial3: true,
      brightness: Brightness.dark,
      canvasColor: Colors.green[900],
      colorScheme: colorScheme,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: primaryGreen,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButtonTheme:
          const FloatingActionButtonThemeData(shape: CircleBorder()),
    );
  }
}
