import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _loading = false;

  Future<void> _signIn() async {
    setState(() => _loading = true);
    try {
      await ref.read(authNotifierProvider).signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Logowanie nieudane: $e',
              style: const TextStyle(color: AppTheme.textPrimary),
            ),
            backgroundColor: AppTheme.surfaceElevated,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryDim.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.25),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'D',
                      style: GoogleFonts.rajdhani(
                        color: AppTheme.primary,
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  'DBD COMPANION',
                  style: GoogleFonts.rajdhani(
                    color: AppTheme.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Zaloguj się, aby kontynuować',
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 48),

                // Divider
                Container(
                  height: 1,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppTheme.border,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Google Sign-In button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: _loading
                      ? Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: AppTheme.primary,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : OutlinedButton(
                          onPressed: _signIn,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: AppTheme.surfaceElevated,
                            side: const BorderSide(
                              color: AppTheme.border,
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Google "G" icon
                              _GoogleIcon(),
                              const SizedBox(width: 12),
                              Text(
                                'Zaloguj przez Google',
                                style: GoogleFonts.rajdhani(
                                  color: AppTheme.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
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

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    final arcR = r * 0.74;
    final sw = size.width * 0.185;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: arcR);

    Paint arc(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.butt;

    // Blue:   top (270°) → clockwise 135° → ends at ~45°  (upper-right + right)
    canvas.drawArc(rect, -1.5708, 2.3562, false, arc(const Color(0xFF4285F4)));
    // Green:  45° → clockwise 75° → ends at 120°         (lower-right + bottom)
    canvas.drawArc(rect, 0.7854, 1.3090, false, arc(const Color(0xFF34A853)));
    // Yellow: 120° → clockwise 60° → ends at 180°        (bottom → lower-left)
    canvas.drawArc(rect, 2.0944, 1.0472, false, arc(const Color(0xFFFBBC05)));
    // Red:    180° → clockwise 90° → ends at 270°        (left → top)
    canvas.drawArc(rect, 3.1416, 1.5708, false, arc(const Color(0xFFEA4335)));

    // Blue horizontal bar: center → right edge (the "G" cutout shelf)
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + arcR, cy),
      arc(const Color(0xFF4285F4)),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
