import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dbd_companion/l10n/generated/app_localizations.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/widgets/widgets.dart';

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
      if (mounted) showAppSnack(context, 'Sign in failed: $e', error: true);
    } finally {
      if (mounted) setState(() => _signingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = ref.watch(themeColorProvider);
    final auth = ref.watch(authNotifierProvider);
    final l10n = AppLocalizations.of(context)!;

    final sections = <Widget>[
      SectionLabel(title: l10n.colorTheme),
      const SizedBox(height: 12),
      _ColorGrid(selectedColor: selectedColor),
      const SizedBox(height: 32),
      SectionLabel(title: l10n.language),
      const SizedBox(height: 12),
      const _LanguagePanel(),
      const SizedBox(height: 32),
      const SectionLabel(title: 'Account'),
      const SizedBox(height: 12),
      _AccountPanel(
        auth: auth,
        signingIn: _signingIn,
        onSignIn: _signInWithGoogle,
        onSignOut: () => ref.read(authNotifierProvider).signOut(),
      ),
      const SizedBox(height: 40),
      const _Footer(),
    ];

    return Scaffold(
      body: AppBackground(
        child: Column(
          children: [
            ContentWidth(
              maxWidth: 640 + 56,
              child: PageHeader(
                showBack: true,
                title: l10n.settings,
                subtitle: 'Appearance, language and account',
              ),
            ),
            Expanded(
              child: ContentWidth(
                maxWidth: 640 + 56,
                child: ListView(
                  padding: pagePadding(context, top: 8, bottom: 32),
                  children: [
                    for (var i = 0; i < sections.length; i++) sections[i].entrance(i ~/ 3),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Color grid ───────────────────────────────────────────────────────────────

class _ColorGrid extends ConsumerWidget {
  final Color selectedColor;
  const _ColorGrid({required this.selectedColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(themeColorProvider.notifier);
    final selected = selectedColor.toARGB32();
    final isPreset = AppTheme.themeColors.any((e) => e.color.toARGB32() == selected);

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 520;
        final cols = wide ? 5 : 2;
        const gap = 8.0;
        final tileWidth = (constraints.maxWidth - gap * (cols - 1)) / cols;

        final tiles = <Widget>[
          for (final entry in AppTheme.themeColors)
            _Swatch(
              name: entry.name,
              color: entry.color,
              selected: entry.color.toARGB32() == selected,
              vertical: wide,
              onTap: () => notifier.setColor(entry.color),
            ),
          _Swatch(
            name: 'Custom',
            color: isPreset ? null : selectedColor,
            selected: !isPreset,
            vertical: wide,
            onTap: () => _pickCustom(context, selectedColor, notifier.setColor),
          ),
        ];

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final t in tiles) SizedBox(width: tileWidth, child: t)],
        );
      },
    );
  }

  Future<void> _pickCustom(
    BuildContext context,
    Color initial,
    ValueChanged<Color> onColorPicked,
  ) async {
    Color pickedColor = initial;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AppDialog(
        title: 'Pick color',
        confirmLabel: 'Select',
        onCancel: () => Navigator.pop(ctx),
        onConfirm: () {
          onColorPicked(pickedColor);
          Navigator.pop(ctx);
        },
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickedColor,
            onColorChanged: (color) => pickedColor = color,
            labelTypes: const [],
            enableAlpha: false,
            portraitOnly: true,
            hexInputBar: true,
            colorPickerWidth: 300,
            pickerAreaHeightPercent: 0.7,
            pickerAreaBorderRadius: BorderRadius.circular(AppShapes.radiusSm),
          ),
        ),
      ),
    );
  }
}

/// Notched tile showing a theme color. `color == null` renders the "custom"
/// placeholder (palette icon on an empty chip).
class _Swatch extends StatelessWidget {
  final String name;
  final Color? color;
  final bool selected;
  final bool vertical;
  final VoidCallback onTap;

  const _Swatch({
    required this.name,
    required this.color,
    required this.selected,
    required this.vertical,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color;
    final chip = Container(
      width: vertical ? double.infinity : 30,
      height: vertical ? 40 : 30,
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: c ?? AppTheme.background,
        shape: AppShapes.notched(
          cut: vertical ? 8 : 6,
          side: BorderSide(
            color: c == null ? AppTheme.borderHighlight : Colors.black.withValues(alpha: 0.25),
          ),
        ),
      ),
      child: c == null
          ? const Icon(Icons.palette_outlined, size: 17, color: AppTheme.textSecondary)
          : null,
    );

    final label = Text(
      name.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppFonts.display(
        fontSize: 14,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
        color: selected ? AppTheme.textPrimary : AppTheme.textSecondary,
        letterSpacing: 1.1,
      ),
    );

    final check = AnimatedOpacity(
      opacity: selected ? 1 : 0,
      duration: const Duration(milliseconds: 160),
      child: Icon(Icons.check, size: 16, color: AppTheme.primary),
    );

    return Semantics(
      selected: selected,
      button: true,
      label: '$name theme color',
      child: AppPanel(
        onTap: onTap,
        selected: selected,
        cut: 8,
        padding: vertical
            ? const EdgeInsets.fromLTRB(8, 8, 8, 8)
            : const EdgeInsets.fromLTRB(8, 8, 10, 8),
        child: vertical
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  chip,
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const SizedBox(width: 2),
                      Expanded(child: label),
                      check,
                    ],
                  ),
                ],
              )
            : Row(
                children: [
                  chip,
                  const SizedBox(width: 12),
                  Expanded(child: label),
                  check,
                ],
              ),
      ),
    );
  }
}

// ─── Language ─────────────────────────────────────────────────────────────────

class _LanguagePanel extends ConsumerWidget {
  const _LanguagePanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final code = locale?.languageCode == 'pl' ? 'pl' : 'en';
    final compact = AppLayout.isCompact(context);

    final segmented = AppSegmented<String>(
      expand: compact,
      value: code,
      onChanged: (v) => ref.read(localeProvider.notifier).setLocale(Locale(v)),
      segments: [
        AppSegment(value: 'en', label: l10n.english),
        AppSegment(value: 'pl', label: l10n.polish),
      ],
    );

    final label = Row(
      children: [
        const Icon(Icons.translate, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Used for menus and labels',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.body(fontSize: 14, color: AppTheme.textSecondary),
          ),
        ),
      ],
    );

    if (compact) return segmented;

    return AppPanel(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const SizedBox(width: 4),
          Expanded(child: label),
          const SizedBox(width: 12),
          segmented,
        ],
      ),
    );
  }
}

// ─── Account ──────────────────────────────────────────────────────────────────

class _AccountPanel extends StatelessWidget {
  final AuthNotifier auth;
  final bool signingIn;
  final VoidCallback onSignIn;
  final VoidCallback onSignOut;

  const _AccountPanel({
    required this.auth,
    required this.signingIn,
    required this.onSignIn,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final compact = AppLayout.isCompact(context);
    final user = auth.user;
    final isGuest = auth.isGuest;

    final String title;
    final String subtitle;
    if (isGuest || user == null) {
      title = 'Guest';
      subtitle = l10n.guestModeDesc;
    } else {
      title =
          user.displayName?.isNotEmpty == true ? user.displayName! : (user.email ?? 'Signed in');
      subtitle = user.displayName?.isNotEmpty == true && user.email != null
          ? user.email!
          : 'Synced with your Google account';
    }

    final avatar = Container(
      width: 48,
      height: 48,
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: AppTheme.surfaceElevated,
        image: !isGuest && user?.photoURL != null
            ? DecorationImage(image: NetworkImage(user!.photoURL!), fit: BoxFit.cover)
            : null,
        shape: AppShapes.notched(cut: 8, side: const BorderSide(color: AppTheme.border)),
      ),
      child: isGuest || user?.photoURL == null
          ? (isGuest || user == null
              ? const Icon(Icons.person_outline, size: 22, color: AppTheme.textSecondary)
              : Text(title[0].toUpperCase(), style: AppFonts.display(fontSize: 20)))
          : null,
    );

    final action = isGuest || user == null
        ? AppButton(
            label: l10n.signInWithGoogle,
            icon: Icons.login,
            isLoading: signingIn,
            expand: compact,
            onPressed: signingIn ? null : onSignIn,
          )
        : AppButton.secondary(
            label: l10n.signOut,
            icon: Icons.logout,
            expand: compact,
            onPressed: onSignOut,
          );

    final identity = Row(
      children: [
        avatar,
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.display(fontSize: 18, letterSpacing: 1.1),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.body(fontSize: 13, color: AppTheme.textSecondary, height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );

    return AppPanel(
      padding: const EdgeInsets.all(16),
      edgeColor: isGuest ? AppTheme.primary : null,
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [identity, const SizedBox(height: 16), action],
            )
          : Row(
              children: [
                Expanded(child: identity),
                const SizedBox(width: 16),
                action,
              ],
            ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const DiamondMark(size: 6, color: AppTheme.borderHighlight),
        const SizedBox(width: 10),
        Text('DBD COMPANION', style: AppFonts.caption(fontSize: 11)),
        const SizedBox(width: 10),
        const DiamondMark(size: 6, color: AppTheme.borderHighlight),
      ],
    );
  }
}
