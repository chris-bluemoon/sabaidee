import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  primaryColor: const Color(0xFF638C6D),
  colorScheme: ColorScheme.fromSwatch(
    primarySwatch: const MaterialColor(
      0xFF638C6D,
      {
        50: Color(0xFFE8F0EB),
        100: Color(0xFFC5D9CC),
        200: Color(0xFF9FC1AA),
        300: Color(0xFF79A988),
        400: Color(0xFF5B946E),
        500: Color(0xFF638C6D),
        600: Color(0xFF587F63),
        700: Color(0xFF4A6E54),
        800: Color(0xFF3C5D45),
        900: Color(0xFF2A4131),
      },
    ),
    accentColor: const Color(0xFFDF6D2D),
  ).copyWith(
    secondary: const Color(0xFFDF6D2D),
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold, color: Color(0xFF2A4131)),
    headlineSmall: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Color(0xFF2A4131)),
    bodyMedium: TextStyle(fontSize: 14.0, color: Color(0xFF2A4131)),
  ),
  buttonTheme: const ButtonThemeData(
    buttonColor: Color(0xFF638C6D),
    textTheme: ButtonTextTheme.primary,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(20)), // More rounded corners
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: const Color(0xFF667BC6),
      textStyle: const TextStyle(fontSize: 16.0),
      elevation: 5, // Add shadow to ElevatedButton
      shadowColor: Colors.black.withOpacity(0.2), // Shadow color
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)), // More rounded corners
      ),
    ),
  ),
  // scaffoldBackgroundColor: Colors.yellow, // Set the background color to yellow
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Color(0xFFFFC0CB), // Compatible with pink
    selectedItemColor: Color(0xFFFFFFFF),
    unselectedItemColor: Color(0xFF808080),
  ),
);