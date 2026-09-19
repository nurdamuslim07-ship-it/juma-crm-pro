import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class EmployeeAvatar extends StatelessWidget {
  const EmployeeAvatar({
    super.key,
    this.avatarUrl,
    required this.fullName,
    this.radius = 24,
  });

  final String? avatarUrl;
  final String fullName;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(avatarUrl!),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.indigo.withValues(alpha: 0.15),
      child: Text(
        initial,
        style: TextStyle(
          color: AppColors.indigo,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.7,
        ),
      ),
    );
  }
}
