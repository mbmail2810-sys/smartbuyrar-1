import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryGreen = Color(0xFF00B200);

  static ThemeData light() => ThemeData(
        fontFamily: 'NotoSans',
        useMaterial3: true,
        brightness: Brightness.light,
        canvasColor: Colors.green[50],
        colorScheme: ColorScheme.fromSeed(seedColor: primaryGreen),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: primaryGreen,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
        ),
        floatingActionButtonTheme:
            const FloatingActionButtonThemeData(shape: CircleBorder()),
      );

  static ThemeData dark() => ThemeData(
        fontFamily: 'NotoSans',
        useMaterial3: true,
        brightness: Brightness.dark,
        canvasColor: Colors.green[900],
        colorScheme: ColorScheme.fromSeed(
            seedColor: primaryGreen, brightness: Brightness.dark),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: primaryGreen,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
        ),
        floatingActionButtonTheme:
            const FloatingActionButtonThemeData(shape: CircleBorder()),
      );
}
