import 'package:flutter/material.dart';

/// Visual feedback only: the child's own gestures, focus and semantics remain intact.
class PressMotion extends StatefulWidget {
  const PressMotion({super.key, required this.child, this.enabled = true});
  final Widget child;
  final bool enabled;
  @override
  State<PressMotion> createState() => _PressMotionState();
}

class _PressMotionState extends State<PressMotion> {
  bool pressed = false;
  bool hovered = false;
  Offset? origin;
  void release() {
    origin = null;
    if (pressed) setState(() => pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) {
        hovered = false;
        release();
        setState(() {});
      },
      child: Listener(
        onPointerDown: widget.enabled
            ? (event) {
                origin = event.position;
                setState(() => pressed = true);
              }
            : null,
        onPointerUp: (_) => release(),
        onPointerCancel: (_) => release(),
        onPointerMove: (event) {
          if (origin != null && (event.position - origin!).distance > 10) {
            release();
          }
        },
        child: AnimatedScale(
          scale: reduce || !widget.enabled
              ? 1
              : pressed
              ? .97
              : hovered
              ? 1.008
              : 1,
          duration: reduce
              ? Duration.zero
              : Duration(milliseconds: pressed ? 100 : 220),
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}

class MotionInkWell extends InkWell {
  const MotionInkWell({
    super.key,
    super.child,
    super.onTap,
    super.borderRadius,
    super.onLongPress,
    super.splashColor,
    super.highlightColor,
  });
  @override
  Widget build(BuildContext context) => PressMotion(
    enabled: onTap != null || onLongPress != null,
    child: super.build(context),
  );
}

/// Uses Material's pressed/hover/focus states, including keyboard activation.
Widget buttonMotion(
  BuildContext context,
  Set<WidgetState> states,
  Widget? child,
) {
  final reduce = MediaQuery.disableAnimationsOf(context);
  final pressed = states.contains(WidgetState.pressed);
  final disabled = states.contains(WidgetState.disabled);
  return AnimatedScale(
    scale: reduce || disabled
        ? 1
        : pressed
        ? .97
        : states.contains(WidgetState.hovered)
        ? 1.008
        : 1,
    duration: reduce
        ? Duration.zero
        : Duration(milliseconds: pressed ? 100 : 220),
    curve: Curves.easeOutCubic,
    child: child,
  );
}
