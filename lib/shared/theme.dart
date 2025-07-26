// lib/shared/theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // To prevent instantiation of this class
  AppTheme._();

  // --- App Colors ---
  static const Color primaryColor = Colors.blue;
  static const Color accentColor = Colors.lightBlueAccent;
  static const Color textColor = Colors.black87;
  static const Color errorColor = Colors.red;

  // --- App ThemeData ---
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: Colors.grey[50],

      appBarTheme: const AppBarTheme(
        color: primaryColor,
        elevation: 1,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor),
        ),
        labelStyle: TextStyle(color: Colors.grey[700]),
      ),

      // You can define text themes, card themes, etc. here
    );
  }
}