import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/auth/auth_service.dart';
import '../models/skill_exchange_models.dart';

//

class AISuggestionService {
  // Environment-provided direct key if passed via flutter run --dart-define=GEMINI_API_KEY=...
  static const String _envGeminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
  );

  /// Hybrid AI Matching:
  /// 1. Algorithmic Candidate Filter & Scoring (Instant, multi-factor)
  /// 2. Generative AI Layer (Enriches rationale & cross-domain insights using backend proxy with .env)
  static Future<List<AIMatchSuggestion>> generateMatchSuggestions({
    required ExchangeCourse myOfferedCourse,
    required List<ExchangeCourse> availableCourses,
  }) async {
    final List<AIMatchSuggestion> results = [];

    for (final course in availableCourses) {
      // Don't compare with user's own courses
      if (course.ownerId == myOfferedCourse.ownerId ||
          course.id == myOfferedCourse.id) {
        continue;
      }

      final scoreDetails = _calculateMatchScore(myOfferedCourse, course);
      final double score = scoreDetails['score'] as double;
      final List<String> matchingTags =
          scoreDetails['matchingTags'] as List<String>;
      final String heuristicReasoning = scoreDetails['reasoning'] as String;

      if (score >= 40.0) {
        results.add(
          AIMatchSuggestion(
            offeredCourse: myOfferedCourse,
            suggestedCourse: course,
            matchPercentage: score,
            matchingTags: matchingTags,
            reasoning: heuristicReasoning,
          ),
        );
      }
    }

    // Sort by match percentage in descending order
    results.sort((a, b) => b.matchPercentage.compareTo(a.matchPercentage));

    // Enhance top recommendations with Gemini Generative AI (Non-blocking / Graceful fallback)
    if (results.isNotEmpty) {
      try {
        final enhancedResults = await _enrichWithGemini(
          offeredCourse: myOfferedCourse,
          candidates: results.take(3).toList(),
        );
        // Replace top 3 with enhanced versions
        for (int i = 0; i < enhancedResults.length; i++) {
          results[i] = enhancedResults[i];
        }
      } catch (e) {
        debugPrint('Gemini enhancement fallback to heuristic: $e');
      }
    }

    return results;
  }

  static Future<List<AIMatchSuggestion>> _enrichWithGemini({
    required ExchangeCourse offeredCourse,
    required List<AIMatchSuggestion> candidates,
  }) async {
    final prompt =
        '''
You are an expert AI Learning & Skill Exchange Advisor for an education platform.
Analyze an offered course and candidate peer courses to provide a concise, high-impact reasoning for why each exchange is beneficial.

User's Offered Course:
- Title: "${offeredCourse.title}"
- Category: "${offeredCourse.category}"
- Tags: ${offeredCourse.tags.join(', ')}
- Level: ${offeredCourse.level.name}

Candidate Courses for Exchange:
${candidates.asMap().entries.map((e) => '${e.key + 1}. ID: ${e.value.suggestedCourse.id} | Title: "${e.value.suggestedCourse.title}" | Category: "${e.value.suggestedCourse.category}" | Level: ${e.value.suggestedCourse.level.name}').join('\n')}

For each candidate, respond with a JSON array of objects with this exact format:
[
  {
    "id": "course_id_here",
    "reasoning": "A concise 1-2 sentence compelling reason highlighting learning synergy, cross-skill benefits, or career value."
  }
]
Return ONLY raw JSON, with no markdown code fences or other text.
''';

    List<dynamic>? parsedList;

    // 1. Try secure backend endpoint (which reads GEMINI_API_KEY from backend/.env)
    try {
      final backendUri = Uri.parse(
        '${AuthService.backendBaseUrl}/api/ai/match-suggestions',
      );
      final response = await http
          .post(
            backendUri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'prompt': prompt}),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map &&
            data['success'] == true &&
            data['suggestions'] is List) {
          parsedList = data['suggestions'] as List<dynamic>;
        }
      }
    } catch (backendError) {
      debugPrint('Backend AI suggestion proxy unavailable: $backendError');
    }

    // 2. Fallback to direct Gemini API only if GEMINI_API_KEY was passed via --dart-define
    if (parsedList == null && _envGeminiApiKey.isNotEmpty) {
      try {
        final directEndpoint =
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_envGeminiApiKey';
        final response = await http
            .post(
              Uri.parse(directEndpoint),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'contents': [
                  {
                    'parts': [
                      {'text': prompt},
                    ],
                  },
                ],
                'generationConfig': {
                  'temperature': 0.3,
                  'maxOutputTokens': 500,
                },
              }),
            )
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final rawText =
              data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
          final cleanJson = rawText
              .replaceAll('```json', '')
              .replaceAll('```', '')
              .trim();
          final parsed = jsonDecode(cleanJson);
          if (parsed is List) {
            parsedList = parsed;
          }
        }
      } catch (directError) {
        debugPrint('Direct Gemini API fallback error: $directError');
      }
    }

    if (parsedList != null) {
      final Map<String, String> reasonsById = {};
      for (final item in parsedList) {
        if (item is Map && item['id'] != null && item['reasoning'] != null) {
          reasonsById[item['id'].toString()] = item['reasoning'].toString();
        }
      }

      return candidates.map((c) {
        final aiReason = reasonsById[c.suggestedCourse.id];
        if (aiReason != null && aiReason.trim().isNotEmpty) {
          return AIMatchSuggestion(
            offeredCourse: c.offeredCourse,
            suggestedCourse: c.suggestedCourse,
            matchPercentage: c.matchPercentage,
            matchingTags: c.matchingTags,
            reasoning: aiReason.trim(),
          );
        }
        return c;
      }).toList();
    }

    return candidates;
  }

  static Map<String, dynamic> calculateMatchScoreFast(
    ExchangeCourse offered,
    ExchangeCourse candidate,
  ) {
    return _calculateMatchScore(offered, candidate);
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
      final tagMatchRatio =
          (matchingTags.length /
                  (offered.tags.isEmpty ? 1 : offered.tags.length))
              .clamp(0.0, 1.0);
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
      final isComplementary = _areCategoriesComplementary(
        offered.category,
        candidate.category,
      );
      if (isComplementary) {
        score += 30.0;
        reasons.add(
          'High cross-domain synergy (${offered.category} ↔ ${candidate.category})',
        );
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
        : 'Recommended based on curriculum synergy and peer engagement.';

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
