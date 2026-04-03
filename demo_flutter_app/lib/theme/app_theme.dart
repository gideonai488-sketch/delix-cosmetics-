import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary crimson: hsl(345, 72%, 40%)
  static const Color crimson = Color(0xFFAF1D41);
  static const Color crimsonLight = Color(0xFFC7385A);
  static const Color crimsonDark = Color(0xFF8A1533);

  // Gold: hsl(38, 70%, 55%)
  static const Color gold = Color(0xFFCF9035);
  static const Color goldLight = Color(0xFFE8B86D);

  // Pure white background requested for a cleaner look.
  static const Color background = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);

  // Text
  static const Color foreground = Color(0xFF1F1F1F);
  static const Color mutedForeground = Color(0xFF737373);

  // Secondary: hsl(345, 30%, 95%)
  static const Color secondary = Color(0xFFF5E8ED);
  static const Color muted = Color(0xFFF7F7F7);

  // Accent: hsl(345, 50%, 92%)
  static const Color accent = Color(0xFFF2DDE5);

  // Border
  static const Color border = Color(0xFFE9E9E9);
  static const Color ink = Color(0xFF121212);
  static const Color success = Color(0xFF1E8A63);
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: AppColors.crimson,
        onPrimary: Colors.white,
        secondary: AppColors.secondary,
        onSecondary: AppColors.crimson,
        surface: AppColors.card,
        onSurface: AppColors.foreground,
        outline: AppColors.border,
        tertiary: AppColors.gold,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.playfairDisplay(
            fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.foreground),
        displayMedium: GoogleFonts.playfairDisplay(
            fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.foreground),
        displaySmall: GoogleFonts.playfairDisplay(
            fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.foreground),
        headlineMedium: GoogleFonts.playfairDisplay(
            fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.foreground),
        headlineSmall: GoogleFonts.playfairDisplay(
            fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.foreground),
        titleLarge: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.foreground),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: AppColors.foreground),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: AppColors.foreground),
        bodySmall: GoogleFonts.inter(fontSize: 12, color: AppColors.mutedForeground),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.card,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.foreground),
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.foreground,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.card,
        indicatorColor: AppColors.accent,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.crimson, size: 24);
          }
          return IconThemeData(color: AppColors.mutedForeground, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.crimson);
          }
          return GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.mutedForeground);
        }),
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 74,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.crimson,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.muted,
        selectedColor: AppColors.crimson,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        side: BorderSide.none,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.muted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 14),
      ),
    );
  }
}
