import 'dart:math' as math;

import 'package:flutter/material.dart';

class NeonBackgroundOrbs extends StatefulWidget {
  const NeonBackgroundOrbs({super.key, this.durationSec = 8});

  final double durationSec;

  @override
  State<NeonBackgroundOrbs> createState() => _NeonBackgroundOrbsState();
}

class _NeonBackgroundOrbsState extends State<NeonBackgroundOrbs>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (widget.durationSec * 1000).round()),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        return AnimatedBuilder(
          animation: _c,
          builder: (context, child) {
            final t = _c.value;
            final s1 = 1 + 0.2 * math.sin(t * math.pi * 2);
            final s2 = 1 + 0.3 * math.cos(t * math.pi * 2);
            return Stack(
              children: [
                Positioned(
                  top: -40 + 20 * math.sin(t * math.pi * 2),
                  right: -60 + 30 * math.cos(t * math.pi * 2),
                  child: Transform.scale(
                    scale: s1,
                    child: _blurOrb(const Color(0xFF8B5CF6)),
                  ),
                ),
                Positioned(
                  bottom: -60 + 30 * math.sin(t * math.pi * 2 + 1),
                  left: -40 + 20 * math.cos(t * math.pi * 2 + 1),
                  child: Transform.scale(
                    scale: s2,
                    child: _blurOrb(const Color(0xFF06B6D4)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _blurOrb(Color color) {
    return IgnorePointer(
      child: Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.22),
              blurRadius: 120,
              spreadRadius: 40,
            ),
          ],
        ),
      ),
    );
  }
}
