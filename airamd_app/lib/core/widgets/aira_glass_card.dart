import 'dart:ui';
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'aira_tap_effect.dart';

/// Glassmorphism card — frosted glass effect with warm tones
class AiraGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double borderRadius;
  final double blur;
  final Color? backgroundColor;
  final double opacity;
  final Border? border;

  const AiraGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.borderRadius = 20,
    this.blur = 16,
    this.backgroundColor,
    this.opacity = 0.55,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return AiraTapEffect(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(AiraSizes.cardPadding),
            decoration: BoxDecoration(
              color: (backgroundColor ?? AiraColors.white).withValues(alpha: opacity),
              borderRadius: BorderRadius.circular(borderRadius),
              border: border ??
                  Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 1.2,
                  ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
