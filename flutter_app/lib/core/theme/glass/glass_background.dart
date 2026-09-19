import 'package:flutter/material.dart';

/// Soft sky and periwinkle light beneath the shared frosted surfaces.
class GlassBackground extends StatelessWidget {
  const GlassBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF0B1728), Color(0xFF122947), Color(0xFF091323)]
              : const [Color(0xFFF8FDFF), Color(0xFFEAF7FF), Color(0xFFF9FCFF)],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.9, -0.7),
            radius: 1.4,
            colors: [
              const Color(0xFF4CAEFF).withValues(alpha: dark ? .18 : .23),
              Colors.transparent,
            ],
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(1, .8),
              radius: 1.2,
              colors: [
                const Color(0xFF758FFF).withValues(alpha: .13),
                Colors.transparent,
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
