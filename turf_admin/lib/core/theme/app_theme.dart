import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Executive Emerald Palette
  static const Color primaryColor = Color(0xFF00A86B); // Vibrant Emerald
  static const Color accentColor = Color(0xFF34D399); // Soft Mint
  static const Color primaryDark = Color(0xFF065F46); // Forest Green
  static const Color headerGreen = Color(0xFF2CB002); // Deep Lush Green
  
  // Luxury Backgrounds
  static const Color bgColor = Color(0xFFF9FAFB); // Neutral Grey-White
  static const Color surfaceColor = Colors.white;
  static const Color cardBorder = Color(0xFFE5E7EB);
  static const Color lightGreenBg = Color(0xFFF1F8E9); // Natural light grass tint
  static const Color lightGreenBorder = Color(0xFFDCEDC8); // Soft leafy border
  
  // Executive Text
  static const Color textMain = Color(0xFF111827); // Deepest Charcoal
  static const Color textSecondary = Color(0xFF4B5563); // Muted Slate
  
  // Bespoke Shadows
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.03),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
    BoxShadow(
      color: primaryColor.withOpacity(0.02),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static const LinearGradient executiveGradient = LinearGradient(
    colors: [Color(0xFF065F46), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bgColor,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        surface: surfaceColor,
        background: bgColor,
      ),
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: textMain, letterSpacing: -0.5),
        displayMedium: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: textMain, letterSpacing: -0.5),
        titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: textMain, fontSize: 22),
        bodyLarge: GoogleFonts.poppins(color: textMain, fontSize: 16),
        bodyMedium: GoogleFonts.poppins(color: textSecondary, fontSize: 14),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: headerGreen,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white, size: 18),
        titleTextStyle: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: cardBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 28),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        hintStyle: GoogleFonts.poppins(color: textSecondary.withOpacity(0.4), fontSize: 14),
      ),
    );
  }
}
