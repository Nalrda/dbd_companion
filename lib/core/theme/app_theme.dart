import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Base Colors (glassmorphism palette) ──────────────────────────────────────
  static const Color background      = Color(0xFF0A0A0F); // deep near-black
  static const Color backgroundSecondary = Color(0xFF111118); // secondary bg
  static const Color surface         = Color(0x0FFFFFFF); // glass white 6%
  static const Color surfaceElevated = Color(0x17FFFFFF); // glass white 9%
  static const Color hoverSurface    = Color(0x1FFFFFFF); // glass white 12%
  static const Color border          = Color(0x14FFFFFF); // glass border 8%
  static const Color borderHighlight = Color(0x1FFFFFFF); // glass border 12%

  // ─── Dynamic primary (updated by ThemeColorNotifier) ────────────────────────
  static Color primary    = const Color(0xFFCC2828); // blood red (default)
  static Color primaryDim = const Color(0xFF7A1515); // dark red (default)
  static Color primaryGlow = const Color(0x44CC2828); // glow (default)

  static const Color accent          = Color(0xFFE05828); // orange-red secondary

  static const Color textPrimary     = Color(0xFFF0EEE9); // warm white
  static const Color textSecondary   = Color(0x80F0EEE9); // warm white 50%
  static const Color textTertiary    = Color(0x4DF0EEE9); // warm white 30%
  static const Color textDim         = Color(0x4DF0EEE9); // alias for tertiary

  // ─── Glow / Atmosphere ──────────────────────────────────────────────────────
  static const Color hexPurple      = Color(0xFF8B35D6); // Entity purple
  static const Color hexPurpleDim   = Color(0xFF3D1270);

  // ─── Gradients ──────────────────────────────────────────────────────────────
  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x17FFFFFF), Color(0x0FFFFFFF)],
  );

  static LinearGradient get primaryGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDim],
  );

  // ─── Theme color palette ─────────────────────────────────────────────────────
  static const List<({String name, Color color})> themeColors = [
    (name: 'Blood',   color: Color(0xFFCC2828)),
    (name: 'Crimson', color: Color(0xFFDC143C)),
    (name: 'Pink',    color: Color(0xFFE91E63)),
    (name: 'Purple',  color: Color(0xFF8B35D6)),
    (name: 'Indigo',  color: Color(0xFF3F51B5)),
    (name: 'Blue',    color: Color(0xFF2196F3)),
    (name: 'Cyan',    color: Color(0xFF00BCD4)),
    (name: 'Teal',    color: Color(0xFF26A69A)),
    (name: 'Green',   color: Color(0xFF4CAF50)),
    (name: 'Lime',    color: Color(0xFF8BC34A)),
    (name: 'Amber',   color: Color(0xFFFF8F00)),
    (name: 'Gold',    color: Color(0xFFFFB300)),
    (name: 'Orange',  color: Color(0xFFE05828)),
    (name: 'Coral',   color: Color(0xFFFF7043)),
    (name: 'Bronze',  color: Color(0xFF8D6E63)),
    (name: 'Silver',  color: Color(0xFF9E9E9E)),
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
      case 'healing':     return const Color(0xFF3E9E44);
      case 'chase':       return const Color(0xFFD4883A);
      case 'stealth':     return const Color(0xFF1A8A6A);
      case 'generator':   return const Color(0xFF2196F3);
      case 'endgame':     return const Color(0xFFCC4A24);
      case 'teamwork':    return const Color(0xFF26A69A);
      case 'hook':        return const Color(0xFFB71C1C);
      case 'information': return const Color(0xFF00B8D4);
      case 'aura':        return const Color(0xFF7E57C2);
      case 'boon':        return const Color(0xFF80CBC4);
      case 'invocation':  return const Color(0xFF6A1B9A);
      case 'exhaustion':  return const Color(0xFFE65100);
      case 'item':        return const Color(0xFFFFB300);
      // Killer
      case 'tracking':    return const Color(0xFF42A5F5);
      case 'control':     return const Color(0xFFEF5350);
      case 'utility':     return const Color(0xFF78909C);
      case 'exposed':     return const Color(0xFFFF6F00);
      case 'mobility':    return const Color(0xFF66BB6A);
      case 'general':     return const Color(0xFF9E9E9E);
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
        surface: const Color(0xFF111118),
        primary: primary,
        secondary: accent,
        onSurface: textPrimary,
        outline: border,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ).copyWith(
        displayLarge: GoogleFonts.outfit(
          fontSize: 28, fontWeight: FontWeight.w700,
          letterSpacing: 2.0, color: textPrimary,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 18, fontWeight: FontWeight.w700,
          letterSpacing: 1.0, color: textPrimary,
        ),
        labelLarge: GoogleFonts.outfit(
          fontSize: 14, fontWeight: FontWeight.w600,
          letterSpacing: 1.2, color: textPrimary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xCC111118),
        indicatorColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
                color: primary, fontSize: 11, fontWeight: FontWeight.w600,
                letterSpacing: 0.5);
          }
          return const TextStyle(color: textSecondary, fontSize: 11);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primary);
          }
          return const IconThemeData(color: Color(0x80F0EEE9));
        }),
      ),
      cardTheme: CardThemeData(
        color: const Color(0x0FFFFFFF),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x14FFFFFF), width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0x0FFFFFFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x14FFFFFF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x14FFFFFF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: Color(0x4DF0EEE9)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dividerTheme: const DividerThemeData(color: Color(0x14FFFFFF), thickness: 1),
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
