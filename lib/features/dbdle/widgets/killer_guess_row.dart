import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/dbdle_providers.dart';

/// One row in the killer guessing table showing attribute comparison results.
class KillerGuessRow extends StatelessWidget {
  final KillerGuess guess;

  const KillerGuessRow({super.key, required this.guess});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Killer name
            Expanded(
              flex: 3,
              child: Text(
                guess.killer.name,
                style: GoogleFonts.rajdhani(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            // Height
            _AttributeCell(
              label: 'HEIGHT',
              value: guess.killer.height.toUpperCase(),
              result: guess.heightMatch
                  ? ComparisonResult.correct
                  : ComparisonResult.higher, // just "wrong", use non-correct styling
              isMatch: guess.heightMatch,
            ),
            const SizedBox(width: 6),
            // Speed
            _AttributeCell(
              label: 'SPEED',
              value: guess.killer.movementSpeed.toStringAsFixed(1),
              result: guess.speedResult,
              isMatch: guess.speedResult == ComparisonResult.correct,
            ),
            const SizedBox(width: 6),
            // Terror Radius
            _AttributeCell(
              label: 'TERROR',
              value: guess.killer.terrorRadius < 0
                  ? '?'
                  : '${guess.killer.terrorRadius}m',
              result: guess.terrorResult,
              isMatch: guess.terrorResult == ComparisonResult.correct,
            ),
          ],
        ),
      ),
    );
  }
}

class _AttributeCell extends StatelessWidget {
  final String label;
  final String value;
  final ComparisonResult result;
  final bool isMatch;

  const _AttributeCell({
    required this.label,
    required this.value,
    required this.result,
    required this.isMatch,
  });

  @override
  Widget build(BuildContext context) {
    final color = isMatch ? const Color(0xFF4CAF50) : const Color(0xFFCC3333);
    final bgColor = isMatch
        ? const Color(0xFF4CAF50).withValues(alpha: 0.12)
        : const Color(0xFFCC3333).withValues(alpha: 0.10);

    IconData? arrowIcon;
    if (!isMatch && result == ComparisonResult.higher) {
      arrowIcon = Icons.arrow_downward_rounded; // guessed value is higher → target is lower → arrow down
    } else if (!isMatch && result == ComparisonResult.lower) {
      arrowIcon = Icons.arrow_upward_rounded;   // guessed value is lower → target is higher → arrow up
    }

    return Expanded(
      flex: 2,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.rajdhani(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isMatch)
                  Icon(Icons.check_rounded, color: color, size: 14)
                else if (arrowIcon != null)
                  Icon(arrowIcon, color: color, size: 13)
                else
                  Icon(Icons.close_rounded, color: color, size: 13),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    value,
                    style: GoogleFonts.rajdhani(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
