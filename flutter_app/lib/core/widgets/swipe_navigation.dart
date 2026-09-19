import 'package:flutter/material.dart';

/// Keeps gestures in the navigation area, leaving page scrolling untouched.
class SwipeNavigation extends StatefulWidget {
  const SwipeNavigation({
    super.key,
    required this.child,
    required this.openLabel,
    required this.closeLabel,
  });
  final Widget child;
  final String openLabel;
  final String closeLabel;
  @override
  State<SwipeNavigation> createState() => _SwipeNavigationState();
}

class _SwipeNavigationState extends State<SwipeNavigation> {
  bool expanded = false;
  double distance = 0;
  void toggle() => setState(() => expanded = !expanded);
  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 260);
    return SafeArea(
      top: false,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: (_) => distance = 0,
        onVerticalDragUpdate: (event) => distance += event.delta.dy,
        onVerticalDragEnd: (event) {
          final speed = event.primaryVelocity ?? 0;
          if (distance.abs() < 18 && speed.abs() < 250) return;
          setState(
            () => expanded = speed.abs() >= 250 ? speed < 0 : distance < 0,
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              button: true,
              expanded: expanded,
              label: expanded ? widget.closeLabel : widget.openLabel,
              child: Tooltip(
                message: expanded ? widget.closeLabel : widget.openLabel,
                child: InkWell(
                  onTap: toggle,
                  child: SizedBox(
                    height: 44,
                    width: double.infinity,
                    child: Center(
                      child: AnimatedContainer(
                        duration: duration,
                        width: expanded ? 36 : 52,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: .65),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration: duration,
              curve: Curves.easeInOutCubic,
              alignment: Alignment.bottomCenter,
              child: ClipRect(
                child: Align(
                  heightFactor: expanded ? 1 : 0,
                  alignment: Alignment.bottomCenter,
                  child: IgnorePointer(
                    ignoring: !expanded,
                    child: ExcludeSemantics(
                      excluding: !expanded,
                      child: ExcludeFocus(
                        excluding: !expanded,
                        child: widget.child,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
