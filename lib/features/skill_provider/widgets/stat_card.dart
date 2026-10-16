import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class StatCard extends StatefulWidget {
  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat();
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    final deep = Color.lerp(color, const Color(0xFF04120F), 0.42)!;
    final lift = Color.lerp(color, Colors.white, 0.22)!;

    return AnimatedBuilder(
      animation: _motion,
      builder: (context, _) {
        final t = _motion.value * math.pi * 2;
        return Container(
          height: 132,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment(-0.8 + 0.25 * math.sin(t), -1),
              end: Alignment(1, 0.8 + 0.2 * math.cos(t)),
              colors: [lift, color, deep],
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.32),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -26 + 10 * math.sin(t),
                top: -28 + 8 * math.cos(t),
                child: _orb(86, Colors.white.withValues(alpha: 0.18)),
              ),
              Positioned(
                left: -22 + 6 * math.cos(t + 1),
                bottom: -30 + 12 * math.sin(t + 0.6),
                child: _orb(70, Colors.white.withValues(alpha: 0.12)),
              ),
              Positioned(
                right: 22 + 14 * math.cos(t),
                bottom: 18 + 8 * math.sin(t),
                child: _orb(10, Colors.white.withValues(alpha: 0.85)),
              ),
              Positioned(
                left: 54 + 8 * math.sin(t + 1.4),
                top: 16 + 5 * math.cos(t),
                child: _orb(6, Colors.white.withValues(alpha: 0.55)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Icon(widget.icon, color: Colors.white, size: 20),
                    ),
                    const Spacer(),
                    Text(
                      widget.value,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1,
                            letterSpacing: -0.4,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _orb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
