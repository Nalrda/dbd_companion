import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Base Colors ────────────────────────────────────────────────────────────
  static const Color background     = Color(0xFF060609); // near-black, cold purple tint
  static const Color surface        = Color(0xFF0D0D15); // dark Entity-realm surface
  static const Color surfaceElevated = Color(0xFF131320); // slightly lifted surface
  static const Color border         = Color(0xFF1E1E30); // dark purple-gray border

  static const Color primary        = Color(0xFFD4883A); // warm amber
  static const Color primaryDim     = Color(0xFF8A5520); // dark amber
  static const Color accent         = Color(0xFFE06040); // coral

  static const Color textPrimary    = Color(0xFFECEAF5); // cool moonlight white
  static const Color textSecondary  = Color(0xFF787896); // purple-gray
  static const Color textDim        = Color(0xFF38384F); // deep dim

  // ─── Glow / Atmosphere ──────────────────────────────────────────────────────
  static const Color primaryGlow    = Color(0x44D4883A); // 27% amber — BoxShadows, overlays
  static const Color hexPurple      = Color(0xFF8B35D6); // Entity purple
  static const Color hexPurpleDim   = Color(0xFF3D1270);

  // ─── Gradients ──────────────────────────────────────────────────────────────
  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF131320), Color(0xFF0D0D15)],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD4883A), Color(0xFF8A5520)],
  );

  // ─── Rarity Colors (offerings/items) ────────────────────────────────────────
  static const Color common    = Color(0xFF9E9E9E);
  static const Color uncommon  = Color(0xFF4CAF50);
  static const Color rare      = Color(0xFF2196F3);
  static const Color veryRare  = Color(0xFF9C27B0);

  // ─── Perk Category Colors ───────────────────────────────────────────────────
  static Color perkCategoryColor(String category) {
    switch (category) {
      case 'hex':          return const Color(0xFF8B35D6); // Entity purple
      case 'chase':        return const Color(0xFFD4883A); // warm amber
      case 'stealth':      return const Color(0xFF1A8A6A); // dark teal
      case 'healing':      return const Color(0xFF3E9E44); // dark green
      case 'generator':    return const Color(0xFF2196F3); // blue
      case 'endgame':      return const Color(0xFFCC4A24); // ember orange
      case 'support':      return const Color(0xFF00A8C0); // deep cyan
      case 'awareness':    return const Color(0xFFE6D032); // muted yellow
      case 'anti-healing': return const Color(0xFFD035E8); // dark pink-purple
      case 'anti-grab':    return const Color(0xFFE84A1A); // deep orange-red
      case 'utility':      return const Color(0xFF9E9E9E); // gray
      default:             return const Color(0xFF38384F);
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
          letterSpacing: 2.0, color: textPrimary,
        ),
        headlineMedium: GoogleFonts.rajdhani(
          fontSize: 18, fontWeight: FontWeight.w700,
          letterSpacing: 1.6, color: textPrimary,
        ),
        labelLarge: GoogleFonts.rajdhani(
          fontSize: 14, fontWeight: FontWeight.w600,
          letterSpacing: 1.2, color: textPrimary,
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
          letterSpacing: 1.4,
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
