import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/models/perk.dart';
import '../../../core/widgets/widgets.dart';

/// Displays a [PerkIcon] with a progressive blur that animates down.
/// [blurSigma] of 0 means fully revealed; higher values mean more blur.
class BlurRevealIcon extends StatelessWidget {
  final Perk perk;
  final double blurSigma;
  final double size;

  const BlurRevealIcon({
    super.key,
    required this.perk,
    required this.blurSigma,
    this.size = 140,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: blurSigma, end: blurSigma),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, sigma, child) {
        if (sigma <= 0.01) return child!;
        return ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: child,
        );
      },
      child: PerkIcon(perk: perk, size: size, showCategoryGlow: false),
    );
  }
}
