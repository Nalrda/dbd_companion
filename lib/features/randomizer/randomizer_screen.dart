import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/perk.dart';
import '../../core/providers/providers.dart';
import 'package:dbd_companion/l10n/generated/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';

class RandomizerScreen extends ConsumerWidget {
  const RandomizerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(randomizerProvider);
    final compact = AppLayout.isCompact(context);
    final role = state.isSurvivor ? l10n.survivor : l10n.killer;

    final roleToggle = RoleToggle(
      expand: compact,
      isSurvivor: state.isSurvivor,
      onChanged: (v) => ref.read(randomizerProvider.notifier).setRole(v),
    );

    final Widget slots;
    if (state.isRolling) {
      slots = _PerkStage(
        compact: compact,
        builder: (i, size) => _RollingDiamond(key: ValueKey('rolling_$i'), index: i, size: size),
      );
    } else if (state.selectedPerks.isEmpty) {
      slots = _PerkStage(
        compact: compact,
        builder: (i, size) => _EmptyDiamond(key: ValueKey('empty_$i'), index: i, size: size),
      );
    } else {
      slots = _ResultSlots(perks: state.selectedPerks, compact: compact);
    }

    final rollButton = AppButton(
      label: l10n.rollPerks,
      icon: Icons.casino_outlined,
      expand: true,
      onPressed: state.isRolling ? null : () => ref.read(randomizerProvider.notifier).roll(),
      isLoading: state.isRolling,
    );

    final canSave = state.selectedPerks.length == 4 && !state.isRolling;

    final stage = AppPanel(
      padding: EdgeInsets.fromLTRB(compact ? 16 : 32, compact ? 16 : 22, compact ? 16 : 32, compact ? 8 : 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionLabel(
            title: l10n.yourBuild,
            count: state.selectedPerks.isEmpty ? null : '${state.selectedPerks.length}/4',
          ),
          SizedBox(height: compact ? 18 : 28),
          slots,
        ],
      ),
    );

    final actions = compact
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              rollButton,
              const SizedBox(height: 10),
              _SaveButton(
                enabled: canSave,
                isSurvivor: state.isSurvivor,
                perks: state.selectedPerks,
                ref: ref,
              ),
            ],
          )
        : Row(
            children: [
              const Spacer(),
              SizedBox(
                width: 220,
                child: _SaveButton(
                  enabled: canSave,
                  isSurvivor: state.isSurvivor,
                  perks: state.selectedPerks,
                  ref: ref,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(width: 300, child: rollButton),
              const Spacer(),
            ],
          );

    return Scaffold(
      body: AppBackground(
        hazeX: 0,
        child: Column(
          children: [
            PageHeader(
              title: l10n.randomizerTitle,
              subtitle: 'Four random $role perks — play what fate hands you',
              bottom: compact ? roleToggle : Row(children: [roleToggle]),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  padding: pagePadding(context, top: compact ? 4 : 8, bottom: 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: compact ? 0 : constraints.maxHeight - 32,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 880),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            stage,
                            SizedBox(height: compact ? 16 : 24),
                            actions,
                          ],
                        ),
                      ),
                    ),
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

// ─── Stage layout ─────────────────────────────────────────────────────────────

/// Lays four perk positions out as a 2×2 grid on phones and a single row on
/// wide screens.
class _PerkStage extends StatelessWidget {
  final bool compact;
  final Widget Function(int index, double size) builder;

  const _PerkStage({required this.compact, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (!compact) {
          final size = ((c.maxWidth - 3 * 32) / 4).clamp(0.0, 148.0);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < 4; i++) Expanded(child: Center(child: builder(i, size))),
            ],
          );
        }
        final size = ((c.maxWidth - 16) / 2 * 0.7).clamp(0.0, 118.0);
        Widget row(int a) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Center(child: builder(a, size))),
                const SizedBox(width: 16),
                Expanded(child: Center(child: builder(a + 1, size))),
              ],
            );
        return Column(children: [row(0), const SizedBox(height: 18), row(2)]);
      },
    );
  }
}

/// Diamond + two-line caption; every slot state shares these metrics so the
/// layout doesn't jump while rolling and revealing.
class _SlotFrame extends StatelessWidget {
  final double size;
  final Widget diamond;
  final Widget caption;

  const _SlotFrame({required this.size, required this.diamond, required this.caption});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size + 28,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: size, height: size, child: diamond),
          const SizedBox(height: 12),
          SizedBox(height: 54, child: caption),
        ],
      ),
    );
  }
}

class _EmptyDiamond extends StatelessWidget {
  final int index;
  final double size;
  const _EmptyDiamond({super.key, required this.index, required this.size});

  @override
  Widget build(BuildContext context) {
    return _SlotFrame(
      size: size,
      diamond: CustomPaint(
        painter: DiamondFramePainter(
          fill: AppTheme.background.withValues(alpha: 0.5),
          stroke: AppTheme.borderHighlight,
        ),
        child: Center(
          child: Text(
            '?',
            style: AppFonts.display(fontSize: size * 0.3, color: AppTheme.textTertiary),
          ),
        ),
      ),
      caption: Text(
        AppLocalizations.of(context)!.perkNumber(index + 1).toUpperCase(),
        textAlign: TextAlign.center,
        style: AppFonts.caption(fontSize: 12),
      ),
    );
  }
}

class _RollingDiamond extends StatelessWidget {
  final int index;
  final double size;
  const _RollingDiamond({super.key, required this.index, required this.size});

  @override
  Widget build(BuildContext context) {
    return _SlotFrame(
      size: size,
      diamond: CustomPaint(
        painter: DiamondFramePainter(
          fill: AppTheme.surfaceElevated,
          stroke: AppTheme.primary.withValues(alpha: 0.45),
        ),
      )
          .animate(onPlay: (c) => c.repeat())
          .shimmer(
            duration: 900.ms,
            delay: (index * 90).ms,
            color: AppTheme.primary.withValues(alpha: 0.25),
          ),
      caption: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: size * 0.6,
          height: 10,
          margin: const EdgeInsets.only(top: 3),
          color: AppTheme.surfaceElevated,
        ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 900.ms, color: AppTheme.border),
      ),
    );
  }
}

class _RevealedDiamond extends StatelessWidget {
  final Perk perk;
  final double size;
  const _RevealedDiamond({super.key, required this.perk, required this.size});

  @override
  Widget build(BuildContext context) {
    return _SlotFrame(
      size: size,
      diamond: Tooltip(
        message: perk.name,
        child: PerkIcon(perk: perk, size: size, showCategoryGlow: true),
      ),
      caption: Column(
        children: [
          Text(
            perk.name.toUpperCase(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppFonts.display(fontSize: 15, letterSpacing: 0.9, height: 1.1),
          ),
          const SizedBox(height: 2),
          Text(
            perk.character,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppFonts.body(fontSize: 12, color: AppTheme.textTertiary),
          ),
        ],
      ),
    );
  }
}

// ─── Sequential reveal ────────────────────────────────────────────────────────

class _ResultSlots extends StatefulWidget {
  final List<Perk> perks;
  final bool compact;
  const _ResultSlots({required this.perks, required this.compact});

  @override
  State<_ResultSlots> createState() => _ResultSlotsState();
}

class _ResultSlotsState extends State<_ResultSlots> {
  int _revealed = 0;

  @override
  void initState() {
    super.initState();
    _revealSequentially();
  }

  @override
  void didUpdateWidget(_ResultSlots old) {
    super.didUpdateWidget(old);
    if (old.perks != widget.perks) {
      setState(() => _revealed = 0);
      _revealSequentially();
    }
  }

  Future<void> _revealSequentially() async {
    for (int i = 0; i < widget.perks.length; i++) {
      await Future.delayed(const Duration(milliseconds: 220));
      if (mounted) setState(() => _revealed = i + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _PerkStage(
      compact: widget.compact,
      builder: (i, size) {
        final isVisible = i < _revealed && i < widget.perks.length;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.7, end: 1.0).animate(anim),
              child: child,
            ),
          ),
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.topCenter,
            children: [...previous, if (current != null) current],
          ),
          child: isVisible
              ? _RevealedDiamond(key: ValueKey('perk_${i}_${widget.perks[i].id}'), perk: widget.perks[i], size: size)
              : _EmptyDiamond(key: ValueKey('placeholder_$i'), index: i, size: size),
        );
      },
    );
  }
}

// ─── Save ─────────────────────────────────────────────────────────────────────

class _SaveButton extends StatelessWidget {
  final bool enabled;
  final bool isSurvivor;
  final List<Perk> perks;
  final WidgetRef ref;

  const _SaveButton({
    required this.enabled,
    required this.isSurvivor,
    required this.perks,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return AppButton.secondary(
      label: AppLocalizations.of(context)!.saveAsBuild,
      icon: Icons.bookmark_border,
      expand: true,
      onPressed: enabled ? () => _showSaveDialog(context) : null,
    );
  }

  Future<void> _showSaveDialog(BuildContext context) async {
    final name = await showAppTextPrompt(
      context,
      title: 'Save build',
      message: 'Name this build to keep it in My Builds.',
      hint: 'Build name...',
      confirmLabel: 'Save',
    );
    if (name == null) return;
    await ref.read(buildsProvider.notifier).create(
          name: name,
          isSurvivor: isSurvivor,
          perkIds: perks.map((p) => p.id).toList(),
        );
    if (context.mounted) showAppSnack(context, 'Build saved!');
  }
}
