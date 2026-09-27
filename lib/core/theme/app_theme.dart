import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Typography ───────────────────────────────────────────────────────────────
// Barlow Condensed for display text (titles, labels, numbers) and Barlow for
// body copy. Both share proportions, so mixed lines stay visually coherent.

class AppFonts {
  AppFonts._();

  /// Condensed display face — titles, section labels, buttons, stats.
  static TextStyle display({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
    double letterSpacing = 0.6,
    double? height,
  }) =>
      GoogleFonts.barlowCondensed(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? AppTheme.textPrimary,
        letterSpacing: letterSpacing,
        height: height,
      );

  /// Body face — descriptions, list subtitles, inputs.
  static TextStyle body({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double letterSpacing = 0,
    double? height,
    FontStyle? fontStyle,
  }) =>
      GoogleFonts.barlow(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? AppTheme.textPrimary,
        letterSpacing: letterSpacing,
        height: height,
        fontStyle: fontStyle,
      );

  /// Small uppercase caption used for section labels and metadata.
  static TextStyle caption({Color? color, double fontSize = 11}) => display(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: color ?? AppTheme.textTertiary,
        letterSpacing: 1.8,
      );
}

// ─── Shapes ───────────────────────────────────────────────────────────────────
// Signature "notched" silhouette: the top-left and bottom-right corners are
// cut at 45°, echoing the in-game lobby panels.

class AppShapes {
  AppShapes._();

  static BeveledRectangleBorder notched({
    double cut = 10,
    BorderSide side = BorderSide.none,
  }) =>
      BeveledRectangleBorder(
        side: side,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(cut),
          bottomRight: Radius.circular(cut),
        ),
      );

  static const double radiusSm = 4;
  static const double radiusMd = 6;
}

// ─── Spacing / layout breakpoints ─────────────────────────────────────────────

class AppLayout {
  AppLayout._();

  /// Below this width the app uses the mobile shell (bottom navigation).
  static const double compactMax = 720;

  /// Above this width the side rail shows full labels.
  static const double expandedMin = 1100;

  /// Maximum readable content width inside a page.
  static const double contentMax = 1080;

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compactMax;
}

class AppTheme {
  AppTheme._();

  // ─── Base colors ────────────────────────────────────────────────────────────
  static const Color background = Color(0xFF0C0B0E); // near-black, warm
  static const Color backgroundSecondary = Color(0xFF131216); // sheets, menus
  static const Color surface = Color(0xFF17161B); // panels
  static const Color surfaceElevated = Color(0xFF1E1D23); // raised / inputs
  static const Color hoverSurface = Color(0xFF26242C); // hover highlight
  static const Color border = Color(0xFF2C2A31); // hairline
  static const Color borderHighlight = Color(0xFF3D3A44); // hovered hairline

  static const Color textPrimary = Color(0xFFECE7DF); // bone white
  static const Color textSecondary = Color(0xFFA29C93); // ash
  static const Color textTertiary = Color(0xFF6E6961); // soot
  static const Color textDim = textTertiary;

  // ─── Semantic ───────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF63B06E); // escaped / win
  static const Color danger = Color(0xFFD0503F); // sacrificed / loss
  static const Color accent = Color(0xFFE05828); // secondary warm accent

  // ─── Dynamic primary (updated by ThemeColorNotifier) ────────────────────────
  static Color primary = const Color(0xFFCC2828);
  static Color primaryDim = const Color(0xFF4A1417);
  static Color primaryGlow = const Color(0x44CC2828);

  /// Primary tinted onto the background — for selected rows and fills.
  static Color get primarySoft => primary.withValues(alpha: 0.12);

  /// Readable foreground on top of a solid [primary] fill.
  static Color get onPrimary =>
      primary.computeLuminance() > 0.45 ? const Color(0xFF111014) : Colors.white;

  // ─── Atmosphere ─────────────────────────────────────────────────────────────
  static const Color hexPurple = Color(0xFF8B35D6); // Entity purple
  static const Color hexPurpleDim = Color(0xFF3D1270);

  // ─── Gradients ──────────────────────────────────────────────────────────────
  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surfaceElevated, surface],
  );

  static LinearGradient get primaryGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primary, Color.lerp(primary, background, 0.35)!],
      );

  // ─── Theme color palette ────────────────────────────────────────────────────
  static const List<({String name, Color color})> themeColors = [
    (name: 'Blood', color: Color(0xFFCC2828)),
    (name: 'Soft Pink', color: Color(0xFFFF75EF)),
    (name: 'Purple', color: Color(0xFF8B35D6)),
    (name: 'Blue', color: Color(0xFF2196F3)),
    (name: 'Cyan', color: Color(0xFF00BCD4)),
    (name: 'Green', color: Color(0xFF4CAF50)),
    (name: 'Orange', color: Color(0xFFE05828)),
    (name: 'Yellow', color: Color(0xFFFADA5E)),
    (name: 'Silver', color: Color(0xFF9E9E9E)),
  ];

  /// Updates the dynamic primary color and its derived variants.
  static void updatePrimaryColor(Color color) {
    primary = color;
    primaryDim = Color.lerp(background, color, 0.32)!;
    primaryGlow = color.withValues(alpha: 0x44 / 255);
  }

  // ─── Rarity colors (offerings/items) ────────────────────────────────────────
  static const Color common = Color(0xFF9E9E9E);
  static const Color uncommon = Color(0xFF4CAF50);
  static const Color rare = Color(0xFF2196F3);
  static const Color veryRare = Color(0xFF9C27B0);

  // ─── Perk category colors ───────────────────────────────────────────────────
  static Color perkCategoryColor(String category) {
    switch (category) {
      // Survivor
      case 'healing':
        return const Color(0xFF3E9E44);
      case 'chase':
        return const Color(0xFFD4883A);
      case 'stealth':
        return const Color(0xFF1A8A6A);
      case 'generator':
        return const Color(0xFF2196F3);
      case 'endgame':
        return const Color(0xFFCC4A24);
      case 'teamwork':
        return const Color(0xFF26A69A);
      case 'hook':
        return const Color(0xFFB71C1C);
      case 'information':
        return const Color(0xFF00B8D4);
      case 'aura':
        return const Color(0xFF7E57C2);
      case 'boon':
        return const Color(0xFF80CBC4);
      case 'invocation':
        return const Color(0xFF6A1B9A);
      case 'exhaustion':
        return const Color(0xFFE65100);
      case 'item':
        return const Color(0xFFFFB300);
      // Killer
      case 'tracking':
        return const Color(0xFF42A5F5);
      case 'control':
        return const Color(0xFFEF5350);
      case 'utility':
        return const Color(0xFF78909C);
      case 'exposed':
        return const Color(0xFFFF6F00);
      case 'mobility':
        return const Color(0xFF66BB6A);
      case 'general':
        return const Color(0xFF9E9E9E);
      default:
        return const Color(0xFF38384F);
    }
  }

  static Color rarityColor(String rarity) {
    switch (rarity) {
      case 'common':
        return common;
      case 'uncommon':
        return uncommon;
      case 'rare':
        return rare;
      case 'very_rare':
        return veryRare;
      default:
        return common;
    }
  }

  // ─── ThemeData ──────────────────────────────────────────────────────────────
  static ThemeData get dark {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.dark);
    const hairline = BorderSide(color: border);

    OutlineInputBorder inputBorder(BorderSide side) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppShapes.radiusSm),
          borderSide: side,
        );

    return base.copyWith(
      scaffoldBackgroundColor: background,
      canvasColor: backgroundSecondary,
      splashFactory: InkSparkle.splashFactory,
      highlightColor: primary.withValues(alpha: 0.06),
      splashColor: primary.withValues(alpha: 0.10),
      hoverColor: Colors.white.withValues(alpha: 0.03),
      colorScheme: ColorScheme.dark(
        surface: surface,
        surfaceContainerHighest: surfaceElevated,
        primary: primary,
        onPrimary: onPrimary,
        secondary: accent,
        error: danger,
        onSurface: textPrimary,
        onSurfaceVariant: textSecondary,
        outline: border,
        outlineVariant: border,
      ),
      textTheme: GoogleFonts.barlowTextTheme(base.textTheme)
          .apply(bodyColor: textPrimary, displayColor: textPrimary)
          .copyWith(
            displayLarge: AppFonts.display(fontSize: 34, letterSpacing: 1.2),
            headlineMedium: AppFonts.display(fontSize: 22, letterSpacing: 1),
            titleLarge: AppFonts.display(fontSize: 20, letterSpacing: 0.8),
            titleMedium: AppFonts.body(fontSize: 16, fontWeight: FontWeight.w600),
            labelLarge: AppFonts.display(fontSize: 15, letterSpacing: 1),
          ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primary,
        selectionColor: primary.withValues(alpha: 0.35),
        selectionHandleColor: primary,
      ),
      iconTheme: const IconThemeData(color: textSecondary, size: 20),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppFonts.display(fontSize: 20, letterSpacing: 1.2),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: AppShapes.notched(cut: 8, side: hairline),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: backgroundSecondary,
        surfaceTintColor: Colors.transparent,
        shape: AppShapes.notched(cut: 14, side: hairline),
        titleTextStyle: AppFonts.display(fontSize: 20, letterSpacing: 1),
        contentTextStyle: AppFonts.body(color: textSecondary, height: 1.45),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: backgroundSecondary,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: backgroundSecondary,
        showDragHandle: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          side: BorderSide(color: border),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surfaceElevated,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: AppShapes.notched(cut: 6, side: hairline),
        textStyle: AppFonts.body(fontSize: 14),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surfaceElevated,
        contentTextStyle: AppFonts.body(fontSize: 14),
        actionTextColor: primary,
        shape: AppShapes.notched(cut: 6, side: hairline),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: surfaceElevated,
          borderRadius: BorderRadius.circular(AppShapes.radiusSm),
          border: Border.all(color: border),
        ),
        textStyle: AppFonts.body(fontSize: 12),
        waitDuration: const Duration(milliseconds: 400),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: border,
        circularTrackColor: Colors.transparent,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(borderHighlight),
        radius: const Radius.circular(2),
        thickness: WidgetStateProperty.all(4),
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1, space: 1),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? primary : Colors.transparent),
        checkColor: WidgetStateProperty.all(onPrimary),
        side: const BorderSide(color: borderHighlight, width: 1.5),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? onPrimary : textSecondary),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? primary : surfaceElevated),
        trackOutlineColor: WidgetStateProperty.all(border),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: border,
        thumbColor: primary,
        overlayColor: primary.withValues(alpha: 0.12),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 0,
        shape: AppShapes.notched(cut: 12),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textSecondary,
          textStyle: AppFonts.display(fontSize: 15, letterSpacing: 1),
          shape: AppShapes.notched(cut: 6),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        isDense: true,
        border: inputBorder(hairline),
        enabledBorder: inputBorder(hairline),
        focusedBorder: inputBorder(BorderSide(color: primary, width: 1.4)),
        errorBorder: inputBorder(const BorderSide(color: danger)),
        hintStyle: AppFonts.body(color: textTertiary),
        labelStyle: AppFonts.body(color: textSecondary),
        prefixIconColor: textTertiary,
        suffixIconColor: textTertiary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: primarySoft,
        side: hairline,
        labelStyle: AppFonts.body(fontSize: 13, color: textSecondary),
        shape: AppShapes.notched(cut: 5),
      ),
    );
  }
}
