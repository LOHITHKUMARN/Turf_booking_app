import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Light Theme Colors
  static const Color lightBg = Colors.white;
  static const Color lightSurface = Color(0xFFE0E0E0); // Darker grey for better card contrast
  static const Color lightText = Colors.black;
  static const Color lightSubtext = Colors.black54;
  
  // Dark Theme Colors
  static const Color darkBg = Color(0xFF262626);
  static const Color darkSurface = Color(0xFF333333);
  static const Color darkText = Colors.white;
  static const Color darkSubtext = Colors.white70;

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.green,
    primaryColor: Colors.green[800],
    scaffoldBackgroundColor: const Color(0xFFFAFAFA), // Lighter background for a cleaner look
    cardColor: Colors.white,
    dividerColor: Colors.grey[300],
    textTheme: GoogleFonts.outfitTextTheme().copyWith(
      bodyLarge: GoogleFonts.outfit(color: lightText),
      bodyMedium: GoogleFonts.outfit(color: lightSubtext),
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.green[800],
      foregroundColor: Colors.white,
      centerTitle: true,
      titleTextStyle: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    useMaterial3: true,
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.green,
    primaryColor: Colors.green[700],
    scaffoldBackgroundColor: darkBg,
    cardColor: darkSurface,
    dividerColor: Colors.white10,
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
      bodyLarge: GoogleFonts.outfit(color: darkText),
      bodyMedium: GoogleFonts.outfit(color: darkSubtext),
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.green[800],
      foregroundColor: Colors.white,
      centerTitle: true,
      titleTextStyle: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
    ),
    useMaterial3: true,
  );
}
