import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/models/build.dart';
import '../../core/models/perk.dart';
import '../../core/providers/providers.dart';
import '../../core/repositories/perk_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';

class BuildDetailScreen extends ConsumerWidget {
  final String buildId;

  const BuildDetailScreen({super.key, required this.buildId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buildsAsync = ref.watch(buildsProvider);

    return buildsAsync.when(
      loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (builds) {
        Build? build;
        try {
          build = builds.firstWhere((b) => b.id == buildId);
        } catch (_) {
          return const Scaffold(
              body: Center(child: Text('Build not found')));
        }

        return _BuildDetailView(build: build);
      },
    );
  }
}

class _BuildDetailView extends StatefulWidget {
  final Build build;
  const _BuildDetailView({required this.build});

  @override
  State<_BuildDetailView> createState() => _BuildDetailViewState();
}

class _BuildDetailViewState extends State<_BuildDetailView> {
  List<Perk> _perks = [];

  @override
  void initState() {
    super.initState();
    _loadPerks();
  }

  Future<void> _loadPerks() async {
    final perks =
        await PerkRepository.instance.getPerksByIds(widget.build.perkIds);
    if (mounted) setState(() => _perks = perks);
  }

  void _shareLink(BuildContext context) {
    final perks = widget.build.perkIds.join(',');
    final name = Uri.encodeComponent(widget.build.name);
    final survivor = widget.build.isSurvivor.toString();
    final path = '/builds/create?survivor=$survivor&name=$name&perks=$perks';
    final url = kIsWeb ? '${Uri.base.origin}$path' : path;
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share link copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showQrCode(BuildContext context) {
    final perks = widget.build.perkIds.join(',');
    final name = Uri.encodeComponent(widget.build.name);
    final survivor = widget.build.isSurvivor.toString();
    final url = 'dbdcompanion://builds/create?survivor=$survivor&name=$name&perks=$perks';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'SHARE BUILD',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  fontFamily: 'Rajdhani',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.build.name,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(
                  data: url,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                  errorStateBuilder: (_, __) =>
                      const SizedBox(width: 200, height: 200),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Scan to import this build\nin another DBD Companion instance',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: url));
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Link copied to clipboard'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: const BorderSide(color: AppTheme.border),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Copy link'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.build.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_outlined),
            tooltip: 'Show QR code',
            onPressed: () => _showQrCode(context),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Copy share link',
            onPressed: () => _shareLink(context),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/builds/${widget.build.id}/edit'),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Role badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryDim.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: AppTheme.primary.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.build.isSurvivor
                            ? Icons.person
                            : Icons.sports_kabaddi,
                        color: AppTheme.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.build.isSurvivor ? 'Survivor' : 'Killer',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const SectionHeader(title: 'PERKS'),
                const SizedBox(height: 12),

                if (_perks.isEmpty && widget.build.perkIds.isNotEmpty)
                  const Center(child: CircularProgressIndicator())
                else if (widget.build.perkIds.isEmpty)
                  const Text(
                    'No perks added to this build.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  )
                else
                  ..._perks.map((perk) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: PerkCard(perk: perk),
                      )),

                if (widget.build.notes != null &&
                    widget.build.notes!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const SectionHeader(title: 'NOTES'),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Text(
                      widget.build.notes!,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],

                if (widget.build.tags.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const SectionHeader(title: 'TAGS'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: widget.build.tags
                        .map((t) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppTheme.border,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                t,
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
