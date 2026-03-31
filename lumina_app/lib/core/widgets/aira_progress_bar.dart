import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// Gradient progress bar for course sessions
class AiraProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double height;

  const AiraProgressBar({
    super.key,
    required this.progress,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AiraColors.creamDk,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: clampedProgress,
        child: Container(
          decoration: BoxDecoration(
            gradient: AiraColors.progressGradient,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
      ),
    );
  }
}
