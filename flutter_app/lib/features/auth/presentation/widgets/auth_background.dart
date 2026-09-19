import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass/liquid_glass.dart';

/// Gradient + floating-orb background shared by every auth screen —
/// matches the legacy web app's login background
/// (`from-sky-200 via-sky-50 to-blue-200` light / `from-slate-950
/// via-slate-900 to-sky-950` dark, see DESIGN_SYSTEM.md).
class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppColors.bgDarkTop,
                    AppColors.bgDarkMid,
                    AppColors.bgDarkBottom,
                  ]
                : [
                    AppColors.bgLightTop,
                    AppColors.bgLightMid,
                    AppColors.bgLightBottom,
                  ],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
                child: Image.asset(
                  'assets/images/living-room.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned.fill(
              child: ColoredBox(
                color: (isDark ? AppColors.bgDarkTop : AppColors.bgLightMid)
                    .withValues(alpha: isDark ? .84 : .7),
              ),
            ),
            Positioned(
              top: -40,
              left: -30,
              child: FloatingOrb(color: AppColors.sky, size: 200),
            ),
            Positioned(
              bottom: -20,
              right: -40,
              child: FloatingOrb(
                color: AppColors.teal,
                size: 220,
                reverse: true,
              ),
            ),
            SafeArea(child: child),
          ],
        ),
      ),
    );
  }
}
