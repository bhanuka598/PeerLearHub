import 'package:flutter/material.dart';
import '../models/skill_exchange_models.dart';

class AISuggestionCard extends StatelessWidget {
  final AIMatchSuggestion suggestion;
  final Function(ExchangeCourse offered, ExchangeCourse target) onInitiateSwap;

  const AISuggestionCard({
    super.key,
    required this.suggestion,
    required this.onInitiateSwap,
  });

  Color _getScoreColor(double score) {
    if (score >= 90) return Colors.green.shade600;
    if (score >= 75) return Colors.teal.shade600;
    if (score >= 60) return Colors.orange.shade700;
    return Colors.blueGrey;
  }

  @override
  Widget build(BuildContext context) {
    final target = suggestion.suggestedCourse;
    final scoreColor = _getScoreColor(suggestion.matchPercentage);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scoreColor.withAlpha(90), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: scoreColor.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.auto_awesome, color: scoreColor, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'AI Match Recommendation',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: scoreColor,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: scoreColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${suggestion.matchPercentage.toStringAsFixed(0)}% FIT',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Based on curriculum complementarity & difficulty',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Target Course Details
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    target.thumbnailUrl,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 70,
                      height: 70,
                      color: Colors.teal.shade700,
                      child: const Icon(Icons.school, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        target.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'By ${target.ownerName} (${target.ownerRole.name.toUpperCase()})',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text('${target.rating}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Text('• ${target.category}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // AI Reasoning
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.teal.shade50.withAlpha(120),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.teal.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '💡 Why this swap works:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF0F766E)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    suggestion.reasoning,
                    style: TextStyle(fontSize: 11, color: Colors.teal.shade900),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Bottom Action
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => onInitiateSwap(suggestion.offeredCourse, target),
                icon: const Icon(Icons.swap_horiz, size: 18),
                label: const Text('Propose Skill Exchange'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
