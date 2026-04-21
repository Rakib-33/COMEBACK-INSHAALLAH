import 'package:flutter/material.dart';

import '../../app_theme.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.size = 64,
    this.radius = 20,
    this.glow = true,
    this.padding = 0,
  });

  final double size;
  final double radius;
  final bool glow;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final iconSize = size * 0.28;

    return Container(
      padding: EdgeInsets.all(padding),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (glow)
            Container(
              width: size * 0.92,
              height: size * 0.92,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius + padding),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.violet.withValues(alpha: 0.34),
                    blurRadius: size * 0.34,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: AppColors.cyan.withValues(alpha: 0.18),
                    blurRadius: size * 0.24,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.violet, AppColors.cyan],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            ),
            child: Icon(
              Icons.bolt_rounded,
              color: Colors.white,
              size: iconSize,
            ),
          ),
        ],
      ),
    );
  }
}
