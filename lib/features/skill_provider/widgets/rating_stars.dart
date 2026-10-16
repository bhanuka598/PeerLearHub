import 'package:flutter/material.dart';

const Color kRatingGold = Color(0xFFF5B301);
const Color kRatingGoldSoft = Color(0xFFFFF6DC);

String ratingMood(double rating) {
  if (rating >= 4.5) return 'Learners love teaching with you';
  if (rating >= 4) return 'Highly rated by learners';
  if (rating >= 3) return 'A solid reputation so far';
  if (rating > 0) return 'Every new rating helps you grow';
  return 'Your first rating will show up here';
}

String ratingChoiceLabel(int stars) {
  switch (stars) {
    case 1:
      return 'Needs work';
    case 2:
      return 'Fair';
    case 3:
      return 'Good';
    case 4:
      return 'Great';
    case 5:
      return 'Excellent';
    default:
      return 'Tap a star to rate';
  }
}

class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.value,
    this.size = 18,
    this.onChanged,
    this.enabled = true,
  });

  final double value;
  final double size;
  final ValueChanged<int>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final interactive = onChanged != null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final star = index + 1;
        final filled = value >= star;
        final half = !filled && value >= star - 0.45;
        final icon = filled
            ? Icons.star_rounded
            : half
                ? Icons.star_half_rounded
                : Icons.star_border_rounded;
        final color = filled || half ? kRatingGold : const Color(0xFFD5DEE2);

        final glyph = Icon(icon, color: color, size: size);
        if (!interactive) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: size * 0.04),
            child: glyph,
          );
        }

        return AnimatedScale(
          scale: filled ? 1.12 : 1,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutBack,
          child: IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: size + 10, minHeight: size + 8),
            onPressed: enabled ? () => onChanged!(star) : null,
            icon: glyph,
          ),
        );
      }),
    );
  }
}
