import 'package:flutter/material.dart';
import 'package:warehouse_management/utils/color_palette.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: ColorPalette.pacificBlue,
      primary: ColorPalette.pacificBlue,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Nunito',
      colorScheme: scheme,
      scaffoldBackgroundColor: ColorPalette.aquaHaze,
      appBarTheme: const AppBarTheme(
        backgroundColor: ColorPalette.pacificBlue,
        foregroundColor: ColorPalette.timberGreen,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 22,
            color: ColorPalette.timberGreen),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: ColorPalette.pacificBlue,
        foregroundColor: Colors.white,
      ),
    );
  }
}
