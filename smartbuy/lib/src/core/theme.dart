import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() => ThemeData(
        fontFamily: 'NotoSans',
        useMaterial3: true,
        brightness: Brightness.light,
        canvasColor: Colors.green[50],
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.limeAccent[700],
          foregroundColor: Colors.white,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.teal[700],
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
            seedColor: Colors.green, brightness: Brightness.dark),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.limeAccent[700],
          foregroundColor: Colors.white,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.teal[700],
        ),
        floatingActionButtonTheme:
            const FloatingActionButtonThemeData(shape: CircleBorder()),
      );
}
