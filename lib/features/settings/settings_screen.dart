import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:dbd_companion/l10n/generated/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/widgets/design_system.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _signingIn = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _signingIn = true);
    try {
      await ref.read(authNotifierProvider).signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign in failed: $e',
                style: const TextStyle(color: AppTheme.textPrimary)),
            backgroundColor: AppTheme.backgroundSecondary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _signingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = ref.watch(themeColorProvider);
    final authNotifier = ref.watch(authNotifierProvider);
    final isGuest = authNotifier.isGuest;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: AppBackground(
        orbs: [
          BackgroundOrb(
            color: selectedColor,
            opacity: 0.2,
            position: Alignment.topRight,
            size: 350,
          ),
        ],
        child: Column(
          children: [
            // Custom AppBar
            RepaintBoundary(
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 8,
                      bottom: 8,
                      left: 4,
                      right: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.background.withValues(alpha: 0.7),
                      border: const Border(
                        bottom: BorderSide(color: AppTheme.border),
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: AppTheme.textPrimary),
                          onPressed: () => context.pop(),
                        ),
                        Text(
                          l10n.settings.toUpperCase(),
                          style: GoogleFonts.outfit(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      // Color Theme section
                      SectionLabel(title: l10n.colorTheme),
                      const SizedBox(height: 16),
                      _ColorGrid(selectedColor: selectedColor),
                      const SizedBox(height: 32),

                      // Language section
                      SectionLabel(title: l10n.language),
                      const SizedBox(height: 16),
                      _LanguageRow(),
                      const SizedBox(height: 32),

                      Container(height: 1, color: AppTheme.border),
                      const SizedBox(height: 24),

                      // Auth action
                      if (isGuest)
                        _AuthButton(
                          onPressed:
                              _signingIn ? null : _signInWithGoogle,
                          isLoading: _signingIn,
                          icon: Icons.login,
                          label: l10n.signInWithGoogle,
                          isPrimary: true,
                        )
                      else
                        _AuthButton(
                          onPressed: () =>
                              ref.read(authNotifierProvider).signOut(),
                          icon: Icons.logout,
                          label: l10n.signOut,
                          isPrimary: false,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Color Grid ───────────────────────────────────────────────────────────────

class _ColorGrid extends ConsumerWidget {
  final Color selectedColor;
  const _ColorGrid({required this.selectedColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: AppTheme.themeColors.map((entry) {
        final isSelected =
            selectedColor.toARGB32() == entry.color.toARGB32();
        return _ColorTile(
          name: entry.name,
          color: entry.color,
          isSelected: isSelected,
          onTap: () =>
              ref.read(themeColorProvider.notifier).setColor(entry.color),
        );
      }).toList(),
    );
  }
}

class _ColorTile extends StatefulWidget {
  final String name;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorTile({
    required this.name,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ColorTile> createState() => _ColorTileState();
}

class _ColorTileState extends State<_ColorTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: widget.isSelected
              ? 1.0
              : _hovered
                  ? 1.05
                  : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 88,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? widget.color.withValues(alpha: 0.12)
                  : AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.isSelected
                    ? widget.color
                    : _hovered
                        ? widget.color.withValues(alpha: 0.4)
                        : AppTheme.border,
                width: widget.isSelected ? 1.5 : 1,
              ),
              boxShadow: widget.isSelected
                  ? [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.3),
                        blurRadius: 14,
                      )
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        widget.color.withValues(alpha: 0.8),
                        widget.color.withValues(alpha: 0.4),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.isSelected
                          ? widget.color
                          : widget.color.withValues(alpha: 0.5),
                      width: widget.isSelected ? 2 : 1.5,
                    ),
                    boxShadow: widget.isSelected
                        ? [
                            BoxShadow(
                              color: widget.color.withValues(alpha: 0.4),
                              blurRadius: 10,
                            )
                          ]
                        : null,
                  ),
                  child: widget.isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 17)
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: widget.isSelected
                        ? widget.color
                        : AppTheme.textSecondary,
                    fontSize: 10,
                    fontWeight: widget.isSelected
                        ? FontWeight.w700
                        : FontWeight.w400,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Language Row ─────────────────────────────────────────────────────────────

class _LanguageRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);

    final isEnSelected = locale == null || locale.languageCode == 'en';
    final isPlSelected = locale?.languageCode == 'pl';

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _LangTile(
          name: l10n.english,
          isSelected: isEnSelected,
          onTap: () => ref
              .read(localeProvider.notifier)
              .setLocale(const Locale('en')),
        ),
        _LangTile(
          name: l10n.polish,
          isSelected: isPlSelected,
          onTap: () => ref
              .read(localeProvider.notifier)
              .setLocale(const Locale('pl')),
        ),
      ],
    );
  }
}

class _LangTile extends StatelessWidget {
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  const _LangTile({
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.12)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary
                : AppTheme.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          name,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ─── Auth Button ──────────────────────────────────────────────────────────────

class _AuthButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData icon;
  final String label;
  final bool isPrimary;

  const _AuthButton({
    required this.onPressed,
    this.isLoading = false,
    required this.icon,
    required this.label,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isPrimary
              ? AppTheme.primary.withValues(alpha: 0.08)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPrimary
                ? AppTheme.primary.withValues(alpha: 0.35)
                : AppTheme.border,
          ),
        ),
        child: isLoading
            ? Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: isPrimary
                        ? AppTheme.primary
                        : AppTheme.textSecondary,
                    strokeWidth: 2,
                  ),
                ),
              )
            : Row(
                children: [
                  Icon(
                    icon,
                    color: isPrimary
                        ? AppTheme.primary
                        : AppTheme.textSecondary,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      color: isPrimary
                          ? AppTheme.primary
                          : AppTheme.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
