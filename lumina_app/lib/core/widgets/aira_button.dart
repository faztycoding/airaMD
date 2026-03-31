import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// Primary gradient button
class AiraButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isOutlined;
  final double? width;

  const AiraButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isOutlined = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return SizedBox(
        width: width,
        height: AiraSizes.buttonHeight,
        child: OutlinedButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: isLoading
              ? const _ButtonLoader()
              : (icon != null ? Icon(icon, size: 20) : const SizedBox.shrink()),
          label: Text(label),
        ),
      );
    }

    return SizedBox(
      width: width,
      height: AiraSizes.buttonHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: onPressed != null && !isLoading
              ? AiraColors.primaryGradient
              : null,
          color: onPressed == null || isLoading
              ? AiraColors.woodPale
              : null,
          borderRadius: BorderRadius.circular(AiraSizes.radiusSm),
        ),
        child: ElevatedButton.icon(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
          ),
          icon: isLoading
              ? const _ButtonLoader()
              : (icon != null
                  ? Icon(icon, size: 20, color: Colors.white)
                  : const SizedBox.shrink()),
          label: Text(
            label,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _ButtonLoader extends StatelessWidget {
  const _ButtonLoader();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: Colors.white,
      ),
    );
  }
}
