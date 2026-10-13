import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/auth/auth_service.dart';
import '../models/skill_exchange_models.dart';

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

  static Future<List<Map<String, dynamic>>> getPersonalizedRecommendations({
    required Map<String, dynamic> learnerProfile,
    required List<dynamic> courses,
  }) async {
    try {
      final backendUri = Uri.parse('${AuthService.backendBaseUrl}/api/ai/recommendations');
      final response = await http.post(
        backendUri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'profile': learnerProfile,
          'courses': courses,
        }),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['success'] == true) {
          final feedList = data['feed'] ?? data['recommendations'];
          if (feedList is List && feedList.isNotEmpty) {
            return List<Map<String, dynamic>>.from(feedList);
          }
        }
      }
    } catch (e) {
      debugPrint('Gemini recommendation service error: $e');
    }

    // Heuristic Fallback matching Learner Goal, Skill Level, Interests & Past Searches
    final goal = (learnerProfile['learningGoal'] ?? learnerProfile['goal'] ?? '').toString().toLowerCase();
    final skillLevel = (learnerProfile['skillLevel'] ?? learnerProfile['level'] ?? 'Beginner').toString().toLowerCase();
    final interests = (learnerProfile['interests'] as List?)
            ?.map((e) => e.toString().toLowerCase())
            .toList() ??
        <String>[];
    final pastSearches = (learnerProfile['searchHistory'] as List?)
            ?.map((e) => e.toString().toLowerCase())
            .toList() ??
        <String>[];

    final completed = (learnerProfile['completedLessons'] as List?)?.map((e) => e.toString()).toSet() ?? {};
    final enrolled = (learnerProfile['enrolledLessons'] as List?)?.map((e) => e.toString()).toSet() ?? {};

    final List<Map<String, dynamic>> scoredCourses = [];

    for (final c in courses) {
      if (c is! Map || c['id'] == null) continue;
      final cid = c['id'].toString();
      if (completed.contains(cid)) continue;

      final title = (c['title'] ?? '').toString().toLowerCase();
      final category = (c['category'] ?? '').toString().toLowerCase();
      final cLevel = (c['level'] ?? '').toString().toLowerCase();
      final tags = (c['tags'] as List?)?.map((t) => t.toString().toLowerCase()).toList() ?? <String>[];
      final fullText = '$title $category ${tags.join(' ')}';

      double score = 50.0;
      final List<String> reasons = [];
      String section = 'trending';

      // 1. Goal alignment
      if (goal.isNotEmpty && (fullText.contains(goal) || goal.split(' ').any((w) => w.length > 3 && fullText.contains(w)))) {
        score += 25.0;
        reasons.add('Matches your goal: "${learnerProfile['learningGoal'] ?? learnerProfile['goal']}"');
        section = 'goal';
      }

      // 2. Skill level match
      if (skillLevel.isNotEmpty && cLevel.contains(skillLevel)) {
        score += 15.0;
        reasons.add('Suitable for your $cLevel level');
      }

      // 3. Interests alignment
      final matchingInterests = interests.where((item) => fullText.contains(item)).toList();
      if (matchingInterests.isNotEmpty) {
        score += (matchingInterests.length * 10.0).clamp(10.0, 20.0);
        reasons.add('Aligned with your interest in ${matchingInterests.join(', ')}');
        if (section != 'goal') section = 'interests';
      }

      // 4. Past searches match
      final matchingSearches = pastSearches.where((q) => fullText.contains(q) || q.split(' ').any((w) => w.length > 3 && fullText.contains(w))).toList();
      if (matchingSearches.isNotEmpty) {
        score += 15.0;
        reasons.add('Based on your past search "${matchingSearches.first}"');
        if (section != 'goal') section = 'past_search';
      }

      // 5. In-progress continuation
      if (enrolled.contains(cid)) {
        score += 10.0;
        reasons.insert(0, 'Continue your enrolled course progress');
        section = 'continue';
      }

      final finalScore = score.clamp(50.0, 99.0).toInt();
      final reasoning = reasons.isNotEmpty
          ? reasons.join(' • ')
          : 'Recommended based on trending peer skills and curriculum topics.';

      scoredCourses.add({
        'courseId': cid,
        'matchScore': finalScore,
        'section': section,
        'reasoning': reasoning,
      });
    }

    scoredCourses.sort((a, b) => (b['matchScore'] as int).compareTo(a['matchScore'] as int));
    return scoredCourses.take(6).toList();
  }

  /// AI Similar Courses: "Students who viewed this also viewed..."
  /// Matches candidate courses against current course using:
  /// 1. Tag & Topic Overlap (Weight: 40%)
  /// 2. Co-Enrollment / Category Affinity (Weight: 35%)
  /// 3. Collaborative View Patterns & Difficulty Balance (Weight: 25%)
  static Future<List<Map<String, dynamic>>> getSimilarCourses({
    required Map<String, dynamic> currentCourse,
    required List<dynamic> allCourses,
    List<String> coEnrolledCourseIds = const [],
    List<String> coViewedCourseIds = const [],
  }) async {
    final currentId = currentCourse['id']?.toString() ?? '';
    final currentTags = (currentCourse['tags'] as List?)
            ?.map((t) => t.toString().toLowerCase())
            .toSet() ??
        <String>{};
    final currentCategory = (currentCourse['category'] ?? '').toString().toLowerCase();
    final currentLevel = (currentCourse['level'] ?? '').toString().toLowerCase();

    // 1. Backend AI Endpoint Attempt
    try {
      final backendUri = Uri.parse('${AuthService.backendBaseUrl}/api/ai/similar-courses');
      final response = await http.post(
        backendUri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'currentCourse': currentCourse,
          'courses': allCourses,
          'coEnrolledCourseIds': coEnrolledCourseIds,
          'coViewedCourseIds': coViewedCourseIds,
        }),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['success'] == true && data['similarCourses'] is List) {
          final list = List<Map<String, dynamic>>.from(data['similarCourses']);
          if (list.isNotEmpty) {
            return list;
          }
        }
      }
    } catch (e) {
      debugPrint('Similar courses backend proxy error: $e');
    }

    // 2. Intelligent Algorithmic / Heuristic Fallback
    final List<Map<String, dynamic>> scoredSimilar = [];

    for (final c in allCourses) {
      if (c is! Map || c['id'] == null) continue;
      final cid = c['id'].toString();
      if (cid == currentId) continue; // Exclude current course

      final candCategory = (c['category'] ?? '').toString().toLowerCase();
      final candLevel = (c['level'] ?? '').toString().toLowerCase();
      final candTags = (c['tags'] as List?)
              ?.map((t) => t.toString().toLowerCase())
              .toSet() ??
          <String>{};

      double score = 40.0;
      final List<String> reasons = [];

      // A. Tag & Topic Overlap
      final sharedTags = currentTags.intersection(candTags);
      if (sharedTags.isNotEmpty) {
        score += (sharedTags.length * 15.0).clamp(15.0, 35.0);
        reasons.add('Shares core topics: ${sharedTags.take(2).join(', ')}');
      }

      // B. Category & Domain Synergy
      if (candCategory == currentCategory) {
        score += 20.0;
        reasons.add('Same ${c['category']} domain');
      } else if (_areCategoriesComplementary(currentCategory, candCategory)) {
        score += 15.0;
        reasons.add('High cross-skill synergy');
      }

      // C. Co-viewed behavioral signal
      if (coViewedCourseIds.contains(cid)) {
        score += 20.0;
        reasons.add('Frequently viewed together by students');
      }

      // D. Co-enrolled behavioral signal
      if (coEnrolledCourseIds.contains(cid)) {
        score += 20.0;
        reasons.add('Popular follow-up enrollment');
      }

      // E. Level progression or match
      if (candLevel == currentLevel) {
        score += 10.0;
      }

      final finalScore = score.clamp(50.0, 99.0).toInt();
      final String reasonText = reasons.isNotEmpty
          ? reasons.join(' • ')
          : 'Popular similar course explored by peer learners.';

      scoredSimilar.add({
        'courseId': cid,
        'similarityScore': finalScore,
        'reasoning': reasonText,
      });
    }

    scoredSimilar.sort((a, b) => (b['similarityScore'] as int).compareTo(a['similarityScore'] as int));
    return scoredSimilar.take(4).toList();
  }

  /// AI Skill-Gap Analysis: Suggests courses to fill missing skills for a target job.
  /// Inputs: targetRole, currentSkills, completedCourses, candidateCourses
  /// Analyzes required skills for targetRole, identifies missing skills (gap),
  /// and scores courses that bridge these missing skills.
  static Future<Map<String, dynamic>> getSkillGapRecommendations({
    required String targetRole,
    required List<String> currentSkills,
    required List<dynamic> completedCourses,
    required List<dynamic> candidateCourses,
  }) async {
    // 1. Try Backend Gemini endpoint
    try {
      final backendUri = Uri.parse('${AuthService.backendBaseUrl}/api/ai/skill-gap');
      final response = await http.post(
        backendUri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'targetRole': targetRole,
          'currentSkills': currentSkills,
          'completedCourses': completedCourses,
          'candidateCourses': candidateCourses,
        }),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['success'] == true && data['data'] is Map) {
          return Map<String, dynamic>.from(data['data']);
        }
      }
    } catch (e) {
      debugPrint('Skill-gap AI backend error: $e');
    }

    // 2. Intelligent Heuristic / Domain Knowledge Skill Gap Analysis
    final Map<String, List<String>> roleRequiredSkills = {
      'mobile developer': ['Flutter', 'Dart', 'State Management', 'REST API', 'Firebase', 'Clean Architecture', 'Git'],
      'frontend developer': ['HTML/CSS', 'JavaScript', 'React', 'Responsive Design', 'TypeScript', 'Web Performance', 'Git'],
      'backend developer': ['Node.js', 'Express', 'Database (SQL/NoSQL)', 'REST APIs', 'Cloud & Docker', 'Security', 'Authentication'],
      'full stack developer': ['Flutter', 'React', 'Node.js', 'Databases', 'Cloud & DevOps', 'API Design', 'System Architecture'],
      'ui/ux designer': ['Figma', 'User Research', 'Wireframing', 'Prototyping', 'Design Systems', 'Usability Testing', 'Interaction Design'],
      'data scientist': ['Python', 'Pandas', 'Machine Learning', 'Data Visualization', 'SQL', 'Statistical Modeling'],
      'ai/ml engineer': ['Python', 'Deep Learning', 'PyTorch/TensorFlow', 'NLP', 'Computer Vision', 'Model Deployment'],
      'cloud engineer': ['AWS/GCP', 'Docker', 'Kubernetes', 'CI/CD Pipelines', 'Linux', 'Infrastructure as Code'],
      'cyber security analyst': ['Network Security', 'Penetration Testing', 'Cryptography', 'Identity & Access', 'Incident Response'],
    };

    final normalizedRole = targetRole.toLowerCase().trim();
    List<String> requiredSkills = [];

    // Find best role key match
    for (final entry in roleRequiredSkills.entries) {
      if (normalizedRole.contains(entry.key) || entry.key.contains(normalizedRole)) {
        requiredSkills = entry.value;
        break;
      }
    }

    if (requiredSkills.isEmpty) {
      requiredSkills = ['Core Fundamentals', 'Framework Mastery', 'Architecture & Testing', 'Production Deployment'];
    }

    final currentSkillsSet = currentSkills.map((s) => s.toLowerCase().trim()).toSet();
    final completedTitles = completedCourses.map((c) => (c is Map ? c['title'] : c.toString()).toLowerCase()).toList();

    // Extract already mastered skills from currentSkills + completedCourses
    final masteredSkills = <String>[];
    final missingSkills = <String>[];

    for (final req in requiredSkills) {
      final reqLow = req.toLowerCase();
      final hasSkill = currentSkillsSet.contains(reqLow) ||
          completedTitles.any((t) => t.contains(reqLow));
      if (hasSkill) {
        masteredSkills.add(req);
      } else {
        missingSkills.add(req);
      }
    }

    // Score courses that address missing skills
    final List<Map<String, dynamic>> recommendedCourses = [];
    final completedCourseIds = completedCourses
        .map((c) => c is Map ? c['id']?.toString() : c.toString())
        .whereType<String>()
        .toSet();

    for (final c in candidateCourses) {
      if (c is! Map || c['id'] == null) continue;
      final cid = c['id'].toString();
      if (completedCourseIds.contains(cid)) continue;

      final title = (c['title'] ?? '').toString();
      final tags = (c['tags'] as List?)?.map((t) => t.toString()).toList() ?? <String>[];
      final fullText = '$title ${tags.join(' ')} ${c['category'] ?? ''}'.toLowerCase();

      final coveredGaps = missingSkills.where((gap) => fullText.contains(gap.toLowerCase())).toList();
      if (coveredGaps.isNotEmpty) {
        final double score = (coveredGaps.length * 30.0 + 35.0).clamp(50.0, 98.0);
        recommendedCourses.add({
          'courseId': cid,
          'coveredSkills': coveredGaps,
          'matchScore': score.toInt(),
          'reasoning': 'Closes critical skill gaps in ${coveredGaps.join(', ')} required for $targetRole.',
        });
      }
    }

    recommendedCourses.sort((a, b) => (b['matchScore'] as int).compareTo(a['matchScore'] as int));

    final totalReq = requiredSkills.length;
    final readinessScore = totalReq == 0 ? 100 : ((masteredSkills.length / totalReq) * 100).round();

    return {
      'targetRole': targetRole.isEmpty ? 'Software Professional' : targetRole,
      'readinessScore': readinessScore,
      'masteredSkills': masteredSkills,
      'missingSkills': missingSkills,
      'recommendedCourses': recommendedCourses.take(4).toList(),
    };
  }
}
