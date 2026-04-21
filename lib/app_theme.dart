import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const bgTop = Color(0xFF0A0B1E);
  static const bgMid = Color(0xFF1A0B2E);
  static const violet = Color(0xFF8B5CF6);
  static const cyan = Color(0xFF06B6D4);
  static const glassBorder = Color.fromRGBO(255, 255, 255, 0.10);
  static const glassFill = Color.fromRGBO(255, 255, 255, 0.05);
  static const textMuted = Color.fromRGBO(255, 255, 255, 0.60);
}

class AppTheme {
  static ThemeData dark() {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bgTop,
    );
    return base.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.violet,
        secondary: AppColors.cyan,
        surface: AppColors.bgTop,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.glassFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color.fromRGBO(139, 92, 246, 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color.fromRGBO(139, 92, 246, 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.violet, width: 2),
        ),
        hintStyle: const TextStyle(color: Color.fromRGBO(255, 255, 255, 0.30)),
        labelStyle: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w500),
      ),
    );
  }

  static BoxDecoration pageBackground() => const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.bgTop, AppColors.bgMid, AppColors.bgTop],
        ),
      );

  static List<BoxShadow> neonPurpleGlow() => [
        BoxShadow(
          color: AppColors.violet.withValues(alpha: 0.35),
          blurRadius: 20,
          spreadRadius: 0,
        ),
      ];
}
