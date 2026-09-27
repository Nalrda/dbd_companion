import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = false;
  bool _guestLoading = false;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  bool get _busy => _loading || _guestLoading;

  Future<void> _signIn() async {
    setState(() => _loading = true);
    try {
      await ref.read(authNotifierProvider).signInWithGoogle();
    } catch (e) {
      if (mounted) showAppSnack(context, 'Sign in failed: $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInAsGuest() async {
    setState(() => _guestLoading = true);
    try {
      await ref.read(authNotifierProvider).signInAsGuest();
    } catch (e) {
      if (mounted) showAppSnack(context, 'Guest sign in failed: $e', error: true);
    } finally {
      if (mounted) setState(() => _guestLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = AppLayout.isCompact(context);
    final steps = <Widget>[
      const _LogoMark(),
      SizedBox(height: compact ? 26 : 32),
      _buildTitles(compact),
      SizedBox(height: compact ? 36 : 44),
      _buildAuthCard(),
      const SizedBox(height: 24),
      _buildFooter(),
    ];
    const delays = [0.0, 0, 0.12, 0, 0.24, 0, 0.36];

    return Scaffold(
      body: AppBackground(
        hazeX: 0,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < steps.length; i++)
                      steps[i] is SizedBox
                          ? steps[i]
                          : _AnimDelay(
                              delay: delays[i].toDouble(),
                              controller: _animController,
                              child: steps[i],
                            ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitles(bool compact) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'DBD COMPANION',
            maxLines: 1,
            style: AppFonts.display(
              fontSize: compact ? 44 : 52,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DiamondMark(size: 5, color: AppTheme.primary),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'Plan your builds. Track your games.',
                textAlign: TextAlign.center,
                style: AppFonts.body(fontSize: 15, color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(width: 10),
            DiamondMark(size: 5, color: AppTheme.primary),
          ],
        ),
      ],
    );
  }

  Widget _buildAuthCard() {
    return AppPanel(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      cut: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('GET STARTED', style: AppFonts.caption(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 14),
          _GoogleButton(
            label: 'Sign in with Google',
            isLoading: _loading,
            onPressed: _busy ? null : _signIn,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('OR', style: AppFonts.caption()),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 14),
          AppButton.secondary(
            label: 'Continue as guest',
            icon: Icons.person_outline,
            expand: true,
            isLoading: _guestLoading,
            onPressed: _busy ? null : _signInAsGuest,
          ),
          const SizedBox(height: 12),
          Text(
            'Guest data is kept on this device only.',
            textAlign: TextAlign.center,
            style: AppFonts.body(fontSize: 12.5, color: AppTheme.textTertiary, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Text(
      'By continuing you agree to our Terms of Service',
      style: AppFonts.body(fontSize: 12, color: AppTheme.textTertiary),
      textAlign: TextAlign.center,
    );
  }
}

// ─── Logo mark ────────────────────────────────────────────────────────────────
// Large version of the side-rail brand: outlined diamond around a solid core.

class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      height: 112,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const DiamondMark(size: 76, color: AppTheme.border, filled: false),
          DiamondMark(size: 60, color: AppTheme.primary.withValues(alpha: 0.10)),
          _ThickDiamond(size: 60, color: AppTheme.primary),
          DiamondMark(size: 24, color: AppTheme.primary),
        ],
      ),
    );
  }
}

/// Outlined diamond with a heavier stroke than [DiamondMark] for large sizes.
class _ThickDiamond extends StatelessWidget {
  final double size;
  final Color color;
  const _ThickDiamond({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.7853981633974483,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(border: Border.all(color: color, width: 2)),
      ),
    );
  }
}

// ─── Animated Delay Wrapper ───────────────────────────────────────────────────

class _AnimDelay extends StatefulWidget {
  final double delay;
  final AnimationController controller;
  final Widget child;

  const _AnimDelay({
    required this.delay,
    required this.controller,
    required this.child,
  });

  @override
  State<_AnimDelay> createState() => _AnimDelayState();
}

class _AnimDelayState extends State<_AnimDelay> {
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    final begin = widget.delay;
    final end = (widget.delay + 0.55).clamp(0.0, 1.0);
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: widget.controller,
        curve: Interval(begin, end, curve: Curves.easeOut),
      ),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: widget.controller,
        curve: Interval(begin, end, curve: Curves.easeOutCubic),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ─── Google button ────────────────────────────────────────────────────────────
// Primary-styled button (see AppButton) with the Google "G" on a white chip.

class _GoogleButton extends StatefulWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _GoogleButton({required this.label, required this.isLoading, required this.onPressed});

  @override
  State<_GoogleButton> createState() => _GoogleButtonState();
}

class _GoogleButtonState extends State<_GoogleButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;
    var fill = _hovered && enabled
        ? Color.lerp(AppTheme.primary, Colors.white, 0.08)!
        : AppTheme.primary;
    var fg = AppTheme.onPrimary;
    if (!enabled && !widget.isLoading) {
      fill = AppTheme.primaryDim;
      fg = AppTheme.textSecondary;
    }
    final shape = AppShapes.notched(cut: 9);

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: 50,
        decoration: ShapeDecoration(color: fill, shape: shape),
        child: Material(
          type: MaterialType.transparency,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? widget.onPressed : null,
            customBorder: shape,
            splashColor: fg.withValues(alpha: 0.12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: AppShapes.notched(cut: 6),
                    ),
                    child: widget.isLoading
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primary,
                            ),
                          )
                        : const _GoogleIcon(),
                  ),
                  Expanded(
                    child: Text(
                      widget.label.toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.display(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: fg,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 38),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Google Icon ──────────────────────────────────────────────────────────────

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  static const _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
  <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
  <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l3.66-2.84z"/>
  <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
</svg>''';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(_svg, width: 20, height: 20);
  }
}
