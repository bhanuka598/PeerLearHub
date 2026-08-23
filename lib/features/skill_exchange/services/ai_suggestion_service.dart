import '../models/skill_exchange_models.dart';

class AISuggestionService {
  /// Evaluates courses against the user's offered course to recommend top swaps
  /// based on Category Affinity, Tag Overlap, and Difficulty Level Complementarity.
  static List<AIMatchSuggestion> generateMatchSuggestions({
    required ExchangeCourse myOfferedCourse,
    required List<ExchangeCourse> availableCourses,
  }) {
    final List<AIMatchSuggestion> results = [];

    for (final course in availableCourses) {
      // Don't compare with user's own courses
      if (course.ownerId == myOfferedCourse.ownerId || course.id == myOfferedCourse.id) {
        continue;
      }

      final scoreDetails = _calculateMatchScore(myOfferedCourse, course);
      final double score = scoreDetails['score'] as double;
      final List<String> matchingTags = scoreDetails['matchingTags'] as List<String>;
      final String reasoning = scoreDetails['reasoning'] as String;

      if (score >= 40.0) {
        results.add(
          AIMatchSuggestion(
            offeredCourse: myOfferedCourse,
            suggestedCourse: course,
            matchPercentage: score,
            matchingTags: matchingTags,
            reasoning: reasoning,
          ),
        );
      }
    }

    // Sort by match percentage in descending order
    results.sort((a, b) => b.matchPercentage.compareTo(a.matchPercentage));
    return results;
  }

  static Map<String, dynamic> _calculateMatchScore(
    ExchangeCourse offered,
    ExchangeCourse candidate,
  ) {
    double score = 0.0;
    final List<String> matchingTags = [];
    final List<String> reasons = [];

    // 1. Tag Overlap (Weight: 45%)
    final offeredTagsLower = offered.tags.map((t) => t.toLowerCase()).toSet();
    for (final tag in candidate.tags) {
      if (offeredTagsLower.contains(tag.toLowerCase())) {
        matchingTags.add(tag);
      }
    }

    if (matchingTags.isNotEmpty) {
      final tagMatchRatio = (matchingTags.length / offered.tags.length).clamp(0.0, 1.0);
      final tagScore = tagMatchRatio * 45.0;
      score += tagScore;
      reasons.add('Shares key skills: ${matchingTags.join(', ')}');
    }

    // 2. Category Synergy / Cross-Disciplinary Value (Weight: 30%)
    if (offered.category.toLowerCase() == candidate.category.toLowerCase()) {
      score += 25.0;
      reasons.add('Same discipline (${candidate.category})');
    } else {
      // Complementary pairings
      final isComplementary = _areCategoriesComplementary(offered.category, candidate.category);
      if (isComplementary) {
        score += 30.0;
        reasons.add('High cross-domain synergy (${offered.category} ↔ ${candidate.category})');
      } else {
        score += 15.0;
        reasons.add('Broad learning expansion');
      }
    }

    // 3. Difficulty Level Balance (Weight: 15%)
    final levelDiff = (offered.level.index - candidate.level.index).abs();
    if (levelDiff == 0) {
      score += 15.0;
      reasons.add('Equal skill level depth');
    } else if (levelDiff == 1) {
      score += 10.0;
      reasons.add('Adjacent skill difficulty');
    } else {
      score += 5.0;
      reasons.add('Beginner-to-Advanced leap');
    }

    // 4. Instructor Credibility & Course Quality Rating (Weight: 10%)
    final ratingBonus = ((candidate.rating - 4.0).clamp(0.0, 1.0)) * 10.0;
    score += ratingBonus;

    // Final normalization
    final finalScore = (score.clamp(45.0, 99.4) * 10).roundToDouble() / 10;
    final finalReasoning = reasons.isNotEmpty
        ? reasons.join(' • ')
        : 'Recommended based on high peer engagement.';

    return {
      'score': finalScore,
      'matchingTags': matchingTags,
      'reasoning': finalReasoning,
    };
  }

  static bool _areCategoriesComplementary(String catA, String catB) {
    final a = catA.toLowerCase();
    final b = catB.toLowerCase();

    final pairs = [
      {'mobile development', 'cloud & devops'},
      {'mobile development', 'artificial intelligence'},
      {'mobile development', 'design & ui/ux'},
      {'mobile development', 'cyber security'},
      {'artificial intelligence', 'data & automation'},
      {'design & ui/ux', 'frontend html/css'},
    ];

    for (final pair in pairs) {
      if (pair.contains(a) && pair.contains(b)) {
        return true;
      }
    }
    return false;
  }
}
