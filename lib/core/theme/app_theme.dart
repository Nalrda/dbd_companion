import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Base Colors ────────────────────────────────────────────────────────────
  static const Color background      = Color(0xFF0A0A0A); // pure near-black
  static const Color surface         = Color(0xFF111111); // dark gray
  static const Color surfaceElevated = Color(0xFF1A1A1A); // slightly lifted dark gray
  static const Color hoverSurface    = Color(0xFF222222); // hover highlight
  static const Color border          = Color(0xFF2A2A2A); // neutral dark gray border

  // ─── Dynamic primary (updated by ThemeColorNotifier) ────────────────────────
  static Color primary    = const Color(0xFFCC2828); // blood red (default)
  static Color primaryDim = const Color(0xFF7A1515); // dark red (default)
  static Color primaryGlow = const Color(0x44CC2828); // glow (default)

  static const Color accent          = Color(0xFFE05828); // orange-red secondary

  static const Color textPrimary     = Color(0xFFF0EEEC); // warm white
  static const Color textSecondary   = Color(0xFF888888); // neutral gray
  static const Color textDim         = Color(0xFF444444); // dark neutral gray

  // ─── Glow / Atmosphere ──────────────────────────────────────────────────────
  static const Color hexPurple      = Color(0xFF8B35D6); // Entity purple (hex perk category)
  static const Color hexPurpleDim   = Color(0xFF3D1270);

  // ─── Gradients ──────────────────────────────────────────────────────────────
  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1A1A), Color(0xFF111111)],
  );

  static LinearGradient get primaryGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDim],
  );

  // ─── Theme color palette ─────────────────────────────────────────────────────
  static const List<({String name, Color color})> themeColors = [
    (name: 'Krew',       color: Color(0xFFCC2828)),
    (name: 'Purpura',    color: Color(0xFF8B35D6)),
    (name: 'Niebieski',  color: Color(0xFF2196F3)),
    (name: 'Zieleń',     color: Color(0xFF4CAF50)),
    (name: 'Pomarańcz',  color: Color(0xFFE05828)),
    (name: 'Złoto',      color: Color(0xFFFFB300)),
    (name: 'Turkus',     color: Color(0xFF26A69A)),
    (name: 'Srebro',     color: Color(0xFF9E9E9E)),
  ];

  /// Updates the dynamic primary color and its derived variants.
  static void updatePrimaryColor(Color color) {
    primary = color;
    primaryDim = Color.fromARGB(
      (color.a * 255).round(),
      (color.r * 255 * 0.47).round(),
      (color.g * 255 * 0.47).round(),
      (color.b * 255 * 0.47).round(),
    );
    primaryGlow = Color.fromARGB(0x44,
      (color.r * 255).round(),
      (color.g * 255).round(),
      (color.b * 255).round(),
    );
  }

  // ─── Rarity Colors (offerings/items) ────────────────────────────────────────
  static const Color common    = Color(0xFF9E9E9E);
  static const Color uncommon  = Color(0xFF4CAF50);
  static const Color rare      = Color(0xFF2196F3);
  static const Color veryRare  = Color(0xFF9C27B0);

  // ─── Perk Category Colors ───────────────────────────────────────────────────
  static Color perkCategoryColor(String category) {
    switch (category) {
      // Survivor
      case 'healing':     return const Color(0xFF3E9E44); // dark green
      case 'chase':       return const Color(0xFFD4883A); // warm amber
      case 'stealth':     return const Color(0xFF1A8A6A); // dark teal
      case 'generator':   return const Color(0xFF2196F3); // blue
      case 'endgame':     return const Color(0xFFCC4A24); // ember orange
      case 'teamwork':    return const Color(0xFF26A69A); // medium teal
      case 'hook':        return const Color(0xFFB71C1C); // dark red
      case 'information': return const Color(0xFF00B8D4); // cyan
      case 'aura':        return const Color(0xFF7E57C2); // purple
      case 'boon':        return const Color(0xFF80CBC4); // light teal
      case 'invocation':  return const Color(0xFF6A1B9A); // deep purple
      case 'exhaustion':  return const Color(0xFFE65100); // deep orange
      case 'item':        return const Color(0xFFFFB300); // amber/gold
      // Killer
      case 'tracking':    return const Color(0xFF42A5F5); // light blue
      case 'control':     return const Color(0xFFEF5350); // red
      case 'utility':     return const Color(0xFF78909C); // blue-grey
      case 'exposed':     return const Color(0xFFFF6F00); // orange
      case 'mobility':    return const Color(0xFF66BB6A); // green
      case 'general':     return const Color(0xFF9E9E9E); // gray
      default:            return const Color(0xFF38384F);
    }
  }

  // ─── ThemeData ──────────────────────────────────────────────────────────────
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.dark(
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
            return TextStyle(
                color: primary, fontSize: 12, fontWeight: FontWeight.w600);
          }
          return const TextStyle(color: textSecondary, fontSize: 12);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primary);
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
          borderSide: BorderSide(color: primary, width: 1.5),
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
