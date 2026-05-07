import 'package:flutter/material.dart';

/// A reusable press-feedback wrapper that scales down and slightly
/// dims its child on tap, giving every button in the app a satisfying
/// "click" feel.  Uses only transform + opacity for GPU-layer perf.
///
/// Usage:
/// ```dart
/// AiraTapEffect(
///   onTap: () => doSomething(),
///   child: MyCardWidget(),
/// )
/// ```
class AiraTapEffect extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// How far the widget scales down (0.95 = 5 % shrink). Default 0.96.
  final double scaleDown;

  /// Opacity when pressed. Default 0.85.
  final double pressedOpacity;

  /// Forward duration (press-in). Default 80 ms — snappy.
  final Duration pressInDuration;

  /// Reverse duration (release). Default 180 ms — smooth spring-out.
  final Duration pressOutDuration;

  /// Accessibility label announced by screen readers.
  ///
  /// Provide this for any tap target whose `child` does not already include
  /// readable text (e.g. icon-only buttons). When omitted, screen readers
  /// fall back to the child's text, which is correct for most card-style
  /// targets in the app.
  final String? semanticsLabel;

  /// Optional longer description for the action — read AFTER the label.
  /// Useful for compound CTAs like "Edit" / "Tap to edit patient profile".
  final String? semanticsHint;

  /// Whether this tap target should be exposed as a button to assistive
  /// tech. Default true. Set to false for purely decorative tap effects
  /// that aren't real navigation / actions.
  final bool isButton;

  const AiraTapEffect({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleDown = 0.96,
    this.pressedOpacity = 0.85,
    this.pressInDuration = const Duration(milliseconds: 80),
    this.pressOutDuration = const Duration(milliseconds: 180),
    this.semanticsLabel,
    this.semanticsHint,
    this.isButton = true,
  });

  @override
  State<AiraTapEffect> createState() => _AiraTapEffectState();
}

class _AiraTapEffectState extends State<AiraTapEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.pressInDuration,
      reverseDuration: widget.pressOutDuration,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: widget.scaleDown).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _opacityAnim = Tween<double>(begin: 1.0, end: widget.pressedOpacity).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _ctrl.forward();

  void _onTapUp(TapUpDetails _) => _ctrl.reverse();

  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    final gesture = GestureDetector(
      behavior: HitTestBehavior.opaque,
      // Tap-down/up animations are visual-only — they should NOT be
      // announced to screen readers, which would otherwise read every
      // press-in/press-out as separate semantic events.
      excludeFromSemantics: true,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnim.value,
            child: Opacity(
              opacity: _opacityAnim.value,
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );

    // The Semantics wrapper exposes this as a focusable, activatable
    // button to TalkBack / VoiceOver. Even when no explicit label is
    // provided we still set `button: true` so the assistive tech reads
    // the child text as a button rather than as plain text.
    return Semantics(
      label: widget.semanticsLabel,
      hint: widget.semanticsHint,
      button: widget.isButton,
      enabled: widget.onTap != null || widget.onLongPress != null,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: gesture,
    );
  }
}
