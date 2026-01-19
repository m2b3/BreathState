import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color deepOceanBlue = Color(0xFF0F172A); 
  static const Color midnightBlue = Color(0xFF1E293B); 
  static const Color softTeal = Color(0xFF2DD4BF); 
  static const Color calmBlue = Color(0xFF38BDF8); 
  static const Color textLight = Color(0xFFF8FAFC); 
  static const Color textDim = Color(0xFF94A3B8); 
  
  static const LinearGradient mainBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0F172A), 
      Color(0xFF020617), 
    ],
  );

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: deepOceanBlue, 
      primaryColor: softTeal,
      colorScheme: const ColorScheme.dark(
        primary: softTeal,
        secondary: calmBlue,
        surface: midnightBlue, 
        onSurface: textLight,
        onPrimary: deepOceanBlue,
      ),
      
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(
          fontSize: 36, 
          fontWeight: FontWeight.bold,
          color: textLight,
          letterSpacing: -1.0,
        ),
        displayMedium: GoogleFonts.outfit(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: textLight,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textLight,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          height: 1.5,
          color: textLight,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          height: 1.5,
          color: textDim,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textLight,
          letterSpacing: 0.5,
        ),
      ),

      cardTheme: CardThemeData(
        color: midnightBlue,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent, 
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textLight,
        ),
        iconTheme: const IconThemeData(color: textLight),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: softTeal,
          foregroundColor: deepOceanBlue,
          elevation: 8,
          shadowColor: softTeal.withOpacity(0.4),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
