import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'aira_tap_effect.dart';

/// Rounded card with warm shadow — base component
class AiraCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double? borderRadius;

  const AiraCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AiraSizes.radiusMd;

    final card = Container(
      padding: padding ?? const EdgeInsets.all(AiraSizes.cardPadding),
      decoration: BoxDecoration(
        color: AiraColors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: AiraShadows.card,
      ),
      child: child,
    );

    if (onTap != null) {
      return AiraTapEffect(onTap: onTap, child: card);
    }
    return card;
  }
}
