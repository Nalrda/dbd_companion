import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/perk.dart';
import '../../core/providers/providers.dart';
import 'package:dbd_companion/l10n/generated/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../core/widgets/design_system.dart';

class RandomizerScreen extends ConsumerWidget {
  const RandomizerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(randomizerProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        orbs: [
          BackgroundOrb(
            color: AppTheme.primary,
            opacity: 0.2,
            position: Alignment.center,
            size: 500,
          ),
        ],
        child: Column(
          children: [
            PageHeader(
              title: PageHeader.text(
                  AppLocalizations.of(context)!.randomizerTitle),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RoleToggle(
                          isSurvivor: state.isSurvivor,
                          onChanged: (v) =>
                              ref.read(randomizerProvider.notifier).setRole(v),
                        ),
                        const SizedBox(height: 32),
                        SectionHeader(
                            title: AppLocalizations.of(context)!.yourBuild),
                        const SizedBox(height: 16),

                        if (state.selectedPerks.isEmpty && !state.isRolling)
                          _EmptySlots()
                        else if (state.isRolling)
                          _LoadingSlots()
                        else
                          _ResultSlots(perks: state.selectedPerks),

                        const SizedBox(height: 32),

                        SizedBox(
                          width: double.infinity,
                          child: DbdButton(
                            label: AppLocalizations.of(context)!.rollPerks,
                            icon: Icons.casino_outlined,
                            onPressed: state.isRolling
                                ? null
                                : () => ref
                                    .read(randomizerProvider.notifier)
                                    .roll(),
                            isLoading: state.isRolling,
                          ),
                        ),

                        if (state.selectedPerks.length == 4) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: _SaveButton(
                              isSurvivor: state.isSurvivor,
                              perks: state.selectedPerks,
                              ref: ref,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],
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

class _EmptySlots extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: PerkSlot(index: i, perk: null),
        ),
      ),
    );
  }
}

class _LoadingSlots extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 1000.ms, color: AppTheme.border),
        ),
      ),
    );
  }
}

class _ResultSlots extends StatefulWidget {
  final List<Perk> perks;
  const _ResultSlots({required this.perks});

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
    return Column(
      children: List.generate(widget.perks.length, (i) {
        final isVisible = i < _revealed;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: Tween<double>(begin: 0.82, end: 1.0).animate(
                CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
              ),
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: isVisible
                ? PerkCard(key: ValueKey('perk_$i'), perk: widget.perks[i])
                : _PlaceholderSlot(key: ValueKey('placeholder_$i'), index: i),
          ),
        );
      }),
    );
  }
}

class _PlaceholderSlot extends StatelessWidget {
  final int index;
  const _PlaceholderSlot({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.question_mark, color: AppTheme.textTertiary, size: 16),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.perkNumber(index + 1),
              style: GoogleFonts.outfit(
                  color: AppTheme.textTertiary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool isSurvivor;
  final List<Perk> perks;
  final WidgetRef ref;

  const _SaveButton({
    required this.isSurvivor,
    required this.perks,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return DbdButton(
      label: AppLocalizations.of(context)!.saveAsBuild,
      icon: Icons.bookmark_border,
      outlined: true,
      onPressed: () => _showSaveDialog(context),
    );
  }

  void _showSaveDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.backgroundSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.border),
        ),
        title: Text('Save Build',
            style: GoogleFonts.outfit(
                color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.outfit(color: AppTheme.textPrimary),
          decoration: const InputDecoration(hintText: 'Build name...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.outfit(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              await ref.read(buildsProvider.notifier).create(
                    name: name,
                    isSurvivor: isSurvivor,
                    perkIds: perks.map((p) => p.id).toList(),
                  );
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Build saved!')),
                );
              }
            },
            child: Text('Save',
                style: GoogleFonts.outfit(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }
}
