import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 64});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      gradient: AppColors.brandLogoGradient,
      borderRadius: BorderRadius.circular(size * .32),
      border: Border.all(color: Colors.white.withValues(alpha: .6)),
      boxShadow: [
        BoxShadow(
          color: AppColors.blue.withValues(alpha: .25),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Icon(LucideIcons.armchair, color: Colors.white, size: size * .55),
  );
}
