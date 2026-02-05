import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color softTeal = Color(0xFF2DD4BF);      
  static const Color deepOceanBlue = Color(0xFF0F172A); 
  static const Color midnightBlue = Color(0xFF1E293B);  
  static const Color paleTeal = Color(0xFFF0FDFA);      
  static const Color pureWhite = Color(0xFFFFFFFF);     

  static const Color roseAccent = Color(0xFFE11D48);   
  static const Color coralRose = Color(0xFFF43F5E);    
  static const Color calmBlue = Color(0xFF38BDF8);    

  static const Color textLight = Color(0xFFF8FAFC);    
  static const Color textDark = Color(0xFF0F172A);    
  static const Color textDimLight = Color(0xFF94A3B8); 
  static const Color textDimDark = Color(0xFF475569); 

  static const LinearGradient darkBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0F172A), 
      Color(0xFF020617), 
    ],
  );

  static const LinearGradient lightBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF0FDFA),
      Color(0xFFE0F2FE), 
    ],
  );

  static TextTheme _buildTextTheme(Color primaryColor, Color dimColor) {
    return TextTheme(
      displayLarge: GoogleFonts.lora(
        fontSize: 36, 
        fontWeight: FontWeight.bold,
        color: primaryColor,
        letterSpacing: -1.0,
      ),
      displayMedium: GoogleFonts.lora(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        letterSpacing: -0.5,
      ),
      titleLarge: GoogleFonts.raleway(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: primaryColor,
      ),
      titleMedium: GoogleFonts.raleway(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
      bodyLarge: GoogleFonts.raleway(
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w500,
        color: primaryColor,
      ),
      bodyMedium: GoogleFonts.raleway(
        fontSize: 14,
        height: 1.5,
        color: dimColor,
        fontWeight: FontWeight.w500, 
      ),
      labelLarge: GoogleFonts.raleway(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: primaryColor,
        letterSpacing: 0.5,
      ),
      labelMedium: GoogleFonts.raleway(
         fontSize: 12,
         fontWeight: FontWeight.w600,
         color: dimColor,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: deepOceanBlue,
      primaryColor: softTeal,
      colorScheme: const ColorScheme.dark(
        primary: softTeal,
        secondary: roseAccent,
        tertiary: coralRose,
        surface: midnightBlue,
        onSurface: textLight,
        onPrimary: deepOceanBlue,
      ),
      textTheme: _buildTextTheme(textLight, textDimLight),
      cardTheme: CardThemeData(
        color: midnightBlue.withOpacity(0.5),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: midnightBlue.withOpacity(0.9),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        titleTextStyle: GoogleFonts.raleway(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textLight,
        ),
        contentTextStyle: GoogleFonts.raleway(
          fontSize: 16,
          color: textDimLight,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: midnightBlue,
        modalBackgroundColor: midnightBlue,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.raleway(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textLight,
        ),
        iconTheme: const IconThemeData(color: textLight),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: coralRose,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: coralRose.withOpacity(0.4),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.raleway(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: paleTeal,
      primaryColor: softTeal,
      colorScheme: const ColorScheme.light(
        primary: softTeal,
        secondary: roseAccent,
        tertiary: coralRose,
        surface: pureWhite,
        onSurface: textDark,
        onPrimary: Colors.white,
      ),
      textTheme: _buildTextTheme(textDark, textDimDark),
      cardTheme: CardThemeData(
        color: pureWhite.withOpacity(0.9), 
        elevation: 4, 
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.black.withOpacity(0.08)), 
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: pureWhite, 
        elevation: 12,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        titleTextStyle: GoogleFonts.raleway(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        contentTextStyle: GoogleFonts.raleway(
          fontSize: 16,
          color: textDimDark,
          height: 1.5,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: pureWhite,
        modalBackgroundColor: pureWhite,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.raleway(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        iconTheme: const IconThemeData(color: textDark),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: coralRose,
          foregroundColor: Colors.white,
          elevation: 6,
          shadowColor: coralRose.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.raleway(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
