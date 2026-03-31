import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/perk.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';

class RandomizerScreen extends ConsumerWidget {
  const RandomizerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(randomizerProvider);

    return Scaffold(
      body: Column(
        children: [
          PageHeader(title: PageHeader.text('Perk Randomizer')),
          Expanded(child: Align(
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
                const SectionHeader(title: 'YOUR BUILD'),
                const SizedBox(height: 16),

                if (state.selectedPerks.isEmpty && !state.isRolling)
                  _EmptySlots()
                else if (state.isRolling)
                  _LoadingSlots()
                else
                  _ResultSlots(perks: state.selectedPerks),

                const SizedBox(height: 32),

                _RollButton(
                  isRolling: state.isRolling,
                  onRoll: () => ref.read(randomizerProvider.notifier).roll(),
                ),

                if (state.selectedPerks.length == 4) ...[
                  const SizedBox(height: 12),
                  _SaveButton(
                    isSurvivor: state.isSurvivor,
                    perks: state.selectedPerks,
                    ref: ref,
                  ),
                ],

                const SizedBox(height: 16),
              ],
            ),
          ),
        ))),
        ],
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
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(
                duration: 1000.ms,
                color: AppTheme.border,
              ),
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
      decoration: const BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.all(Radius.circular(12)),
        border: Border.fromBorderSide(BorderSide(color: AppTheme.border)),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.question_mark, color: AppTheme.textDim, size: 16),
            const SizedBox(width: 8),
            Text(
              'Perk ${index + 1}',
              style: const TextStyle(color: AppTheme.textDim, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _RollButton extends StatelessWidget {
  final bool isRolling;
  final VoidCallback onRoll;

  const _RollButton({required this.isRolling, required this.onRoll});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DbdButton(
        label: 'Roll Perks',
        icon: Icons.casino_outlined,
        onPressed: isRolling ? null : onRoll,
        isLoading: isRolling,
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
    return SizedBox(
      width: double.infinity,
      child: DbdButton(
        label: 'Save as Build',
        icon: Icons.bookmark_border,
        outlined: true,
        onPressed: () => _showSaveDialog(context),
      ),
    );
  }

  void _showSaveDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Save Build',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(hintText: 'Build name...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
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
            child: const Text('Save',
                style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }
}
