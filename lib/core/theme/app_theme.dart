import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Base Colors ────────────────────────────────────────────────────────────
  static const Color background     = Color(0xFF0A0A0F);
  static const Color surface        = Color(0xFF13131A);
  static const Color surfaceElevated = Color(0xFF1C1C26);
  static const Color border         = Color(0xFF2A2A38);

  static const Color primary        = Color(0xFFE8223A);
  static const Color primaryDim     = Color(0xFF8B1424);
  static const Color accent         = Color(0xFFFF6B35);

  static const Color textPrimary    = Color(0xFFF0F0F5);
  static const Color textSecondary  = Color(0xFF8A8A9A);
  static const Color textDim        = Color(0xFF4A4A5A);

  // ─── Glow / Atmosphere ──────────────────────────────────────────────────────
  static const Color primaryGlow    = Color(0x33E8223A); // 20% red — BoxShadows, overlays
  static const Color hexPurple      = Color(0xFF7B2FBE); // hex perk accent
  static const Color hexPurpleDim   = Color(0xFF3B1366);

  // ─── Gradients ──────────────────────────────────────────────────────────────
  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1C1C26), Color(0xFF13131A)],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8223A), Color(0xFFB01830)],
  );

  // ─── Rarity Colors (offerings/items) ────────────────────────────────────────
  static const Color common    = Color(0xFF9E9E9E);
  static const Color uncommon  = Color(0xFF4CAF50);
  static const Color rare      = Color(0xFF2196F3);
  static const Color veryRare  = Color(0xFF9C27B0);

  // ─── Perk Category Colors ───────────────────────────────────────────────────
  static Color perkCategoryColor(String category) {
    switch (category) {
      case 'hex':          return const Color(0xFF7B2FBE); // purple
      case 'chase':        return const Color(0xFFE8223A); // red
      case 'stealth':      return const Color(0xFF1B9E77); // dark teal
      case 'healing':      return const Color(0xFF4CAF50); // green
      case 'generator':    return const Color(0xFF2196F3); // blue
      case 'endgame':      return const Color(0xFFFF6B35); // orange
      case 'support':      return const Color(0xFF00BCD4); // cyan
      case 'awareness':    return const Color(0xFFFFEB3B); // yellow
      case 'anti-healing': return const Color(0xFFE040FB); // pink-purple
      case 'anti-grab':    return const Color(0xFFFF5722); // deep orange
      case 'utility':      return const Color(0xFF9E9E9E); // gray
      default:             return const Color(0xFF4A4A5A);
    }
  }

  // ─── ThemeData ──────────────────────────────────────────────────────────────
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        surface: surface,
        primary: primary,
        secondary: accent,
        onSurface: textPrimary,
        outline: border,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ).copyWith(
        // Rajdhani for display / headline / label
        displayLarge: GoogleFonts.rajdhani(
          fontSize: 28, fontWeight: FontWeight.w700,
          letterSpacing: 1.5, color: textPrimary,
        ),
        headlineMedium: GoogleFonts.rajdhani(
          fontSize: 18, fontWeight: FontWeight.w700,
          letterSpacing: 1.2, color: textPrimary,
        ),
        labelLarge: GoogleFonts.rajdhani(
          fontSize: 14, fontWeight: FontWeight.w600,
          letterSpacing: 0.8, color: textPrimary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.rajdhani(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primaryDim,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
                color: primary, fontSize: 12, fontWeight: FontWeight.w600);
          }
          return const TextStyle(color: textSecondary, fontSize: 12);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primary);
          }
          return const IconThemeData(color: textSecondary);
        }),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textDim),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
    );
  }

  static Color rarityColor(String rarity) {
    switch (rarity) {
      case 'common':    return common;
      case 'uncommon':  return uncommon;
      case 'rare':      return rare;
      case 'very_rare': return veryRare;
      default:          return common;
    }
  }
}
