import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/auth/auth_service.dart';
import '../../../core/config/gemini_key.dart';

class LessonAiException implements Exception {
  LessonAiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Lesson copy and cover suggested from a title.
///
/// Availability, pricing, exchange type, location, and playlist URLs are never
/// included. Callers decide which of these values to keep.
class LessonAiDraft {
  const LessonAiDraft({
    this.description,
    this.learningOutcomes = const [],
    this.category,
    this.skillLevel,
    this.duration,
    this.lessonType,
    this.learningMaterials = const [],
    this.thumbnailBytes,
    this.thumbnailMimeType,
    this.thumbnailError,
  });

  final String? description;
  final List<String> learningOutcomes;
  final String? category;
  final String? skillLevel;
  final String? duration;
  final String? lessonType;
  final List<String> learningMaterials;
  final Uint8List? thumbnailBytes;
  final String? thumbnailMimeType;
  final String? thumbnailError;

  bool get hasText =>
      (description != null && description!.trim().isNotEmpty) ||
      learningOutcomes.isNotEmpty ||
      category != null ||
      skillLevel != null ||
      duration != null ||
      lessonType != null ||
      learningMaterials.isNotEmpty;
}

class LessonAiService {
  const LessonAiService._();

  static const _definedGeminiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const _definedBackendUrl = String.fromEnvironment('BACKEND_URL');

  static const _textModels = [
    'gemini-3.5-flash-lite',
    'gemini-3.5-flash',
    'gemini-flash-lite-latest',
  ];
  static const _imageModels = [
    'gemini-3.1-flash-image',
    'gemini-2.5-flash-image',
  ];
  static const _categories = [
    'Programming',
    'Design',
    'Business',
    'Languages',
    'Music',
    'Photography',
    'Cooking',
    'Other',
  ];
  static const _levels = ['Beginner', 'Intermediate', 'Advanced'];
  static const _durations = [
    '30 minutes',
    '1 hour',
    '1.5 hours',
    '2 hours',
    '3 hours',
  ];
  static const _lessonTypes = ['Online', 'In Person', 'Both'];

  static String get _geminiApiKey {
    final defined = _definedGeminiKey.trim();
    if (defined.isNotEmpty) return defined;
    return localGeminiApiKey.trim();
  }

  /// A phone install cannot reach the emulator address `10.0.2.2`.
  /// Call Gemini directly unless a real backend URL was compiled in.
  static bool get _useOnDeviceGemini =>
      !kIsWeb && _definedBackendUrl.trim().isEmpty && _geminiApiKey.isNotEmpty;

  static Future<LessonAiDraft> draftLesson({
    required String title,
    bool includeText = true,
    bool includeThumbnail = true,
  }) async {
    final trimmed = title.trim();
    if (trimmed.length < 3) {
      throw LessonAiException('Add a lesson title first.');
    }

    if (_useOnDeviceGemini) {
      return _draftOnDevice(
        title: trimmed,
        includeText: includeText,
        includeThumbnail: includeThumbnail,
      );
    }
    return _draftViaBackend(
      title: trimmed,
      includeText: includeText,
      includeThumbnail: includeThumbnail,
    );
  }

  static Future<LessonAiDraft> _draftOnDevice({
    required String title,
    required bool includeText,
    required bool includeThumbnail,
  }) async {
    Map<String, dynamic>? draft;
    if (includeText) {
      draft = await _generateLessonText(title);
    }

    Uint8List? thumbnailBytes;
    String? thumbnailMimeType;
    String? thumbnailError;
    if (includeThumbnail) {
      final image = await _generateThumbnail(title);
      thumbnailBytes = image?.bytes;
      thumbnailMimeType = image?.mimeType;
      thumbnailError = image?.error;
    }

    if (draft == null && thumbnailBytes == null) {
      throw LessonAiException(
        thumbnailError ??
            (includeText
                ? 'Could not draft the lesson details.'
                : 'Could not generate a lesson thumbnail.'),
      );
    }

    return LessonAiDraft(
      description: _stringOrNull(draft?['description']),
      learningOutcomes: _stringList(draft?['learningOutcomes']),
      category: _stringOrNull(draft?['category']),
      skillLevel: _stringOrNull(draft?['skillLevel']),
      duration: _stringOrNull(draft?['duration']),
      lessonType: _stringOrNull(draft?['lessonType']),
      learningMaterials: _stringList(draft?['learningMaterials']),
      thumbnailBytes: thumbnailBytes,
      thumbnailMimeType: thumbnailMimeType,
      thumbnailError: thumbnailError,
    );
  }

  static Future<Map<String, dynamic>> _generateLessonText(String title) async {
    final prompt =
        '''
You are helping a teacher draft a peer-learning lesson on PeerLearnHub.
Use only the lesson title. Do not invent a price, schedule, meeting link, exchange type, or YouTube URL.

Title: "$title"

Return ONLY raw JSON with this shape:
{
  "description": "2 to 3 sentences about what the learner will do",
  "learningOutcomes": ["short outcome", "short outcome", "short outcome"],
  "category": "Programming | Design | Business | Languages | Music | Photography | Cooking | Other",
  "skillLevel": "Beginner | Intermediate | Advanced",
  "duration": "30 minutes | 1 hour | 1.5 hours | 2 hours | 3 hours",
  "lessonType": "Online | In Person | Both",
  "learningMaterials": ["resource name", "resource name"]
}

Rules:
- category, skillLevel, duration, and lessonType must be exactly one of the listed values.
- learningOutcomes: 3 to 5 specific results, no numbering.
- learningMaterials: 3 to 4 resource names only. No URLs.
- Do not include availability, price, location, or video links.
''';

    Object? lastError;
    for (final model in _textModels) {
      try {
        final response = await _postGemini(model, {
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {'temperature': 0.4, 'maxOutputTokens': 1200},
        }, const Duration(seconds: 30));
        if (response.statusCode == 429) {
          lastError = LessonAiException(
            'The AI quota is used up for now. You can still fill the form yourself.',
          );
          continue;
        }
        if (response.statusCode != 200) {
          debugPrint('Lesson AI text failed: $model ${response.statusCode}');
          lastError = LessonAiException('Could not draft the lesson details.');
          continue;
        }

        final data = _decodeBody(response.body);
        final rawText = _candidateText(data);
        if (rawText.isEmpty) {
          lastError = LessonAiException('Could not read the AI lesson draft.');
          continue;
        }

        final parsed = _extractJson(rawText);
        final description = _stringOrNull(parsed['description']);
        final outcomes = _stringList(
          parsed['learningOutcomes'],
        ).take(5).toList();
        if (description == null || outcomes.isEmpty) {
          lastError = LessonAiException('The AI lesson draft was incomplete.');
          continue;
        }

        return {
          'description': description,
          'learningOutcomes': outcomes,
          'category': _pick(parsed['category'], _categories, 'Other'),
          'skillLevel': _pick(parsed['skillLevel'], _levels, 'Beginner'),
          'duration': _pick(parsed['duration'], _durations, '1 hour'),
          'lessonType': _pick(parsed['lessonType'], _lessonTypes, 'Online'),
          'learningMaterials': _stringList(
            parsed['learningMaterials'],
          ).take(4).toList(),
        };
      } on LessonAiException catch (error) {
        lastError = error;
      } on TimeoutException {
        lastError = LessonAiException(
          'Could not reach the AI service. You can still fill the form yourself.',
        );
      } catch (error) {
        debugPrint('Lesson AI text failed: $model $error');
        lastError = LessonAiException(
          error is http.ClientException
              ? 'Could not reach the AI service. You can still fill the form yourself.'
              : 'Could not draft the lesson details.',
        );
      }
    }

    if (lastError is LessonAiException) throw lastError;
    throw LessonAiException('Could not draft the lesson details.');
  }

  static Future<({Uint8List? bytes, String? mimeType, String? error})?>
  _generateThumbnail(String title) async {
    final prompt =
        'Create a clean 16:9 landscape cover illustration for a peer-learning lesson titled "$title". Show a simple educational scene that matches the subject. No words, letters, numbers, logos, or watermarks. Soft lighting, modern flat style, uncluttered background.';
    String? quotaError;
    for (final model in _imageModels) {
      try {
        final response = await _postGemini(model, {
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {
            'responseModalities': ['IMAGE'],
            'imageConfig': {'aspectRatio': '16:9'},
          },
        }, const Duration(seconds: 25));
        if (response.statusCode == 429) {
          quotaError =
              'Lesson text was filled. Thumbnail generation is not included on the free Gemini plan.';
          break;
        }
        if (response.statusCode != 200) {
          debugPrint('Lesson AI image failed: $model ${response.statusCode}');
          continue;
        }
        final data = _decodeBody(response.body);
        final image = _candidateImage(data);
        if (image != null) {
          return (bytes: image.bytes, mimeType: image.mimeType, error: null);
        }
      } catch (error) {
        debugPrint('Lesson AI image failed: $model $error');
      }
    }
    return (bytes: null, mimeType: null, error: quotaError);
  }

  static Future<http.Response> _postGemini(
    String model,
    Map<String, dynamic> body,
    Duration timeout,
  ) {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=${Uri.encodeQueryComponent(_geminiApiKey)}',
    );
    return http
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(timeout);
  }

  static Future<LessonAiDraft> _draftViaBackend({
    required String title,
    required bool includeText,
    required bool includeThumbnail,
  }) async {
    final uri = Uri.parse('${AuthService.backendBaseUrl}/api/ai/lesson-draft');
    final http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'title': title,
              'includeText': includeText,
              'includeThumbnail': includeThumbnail,
            }),
          )
          .timeout(const Duration(seconds: 90));
    } catch (_) {
      throw LessonAiException(
        'Could not reach the AI service. You can still fill the form yourself.',
      );
    }

    Map<String, dynamic> body = {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) body = Map<String, dynamic>.from(decoded);
    } catch (_) {
      body = {};
    }

    if (response.statusCode != 200 || body['success'] != true) {
      final message = body['message']?.toString().trim();
      throw LessonAiException(
        message != null && message.isNotEmpty
            ? message
            : 'Could not draft the lesson details.',
      );
    }

    final draftMap = body['draft'];
    final thumbnailMap = body['thumbnail'];
    final thumbnail = thumbnailMap is Map
        ? _decodeThumbnail(thumbnailMap)
        : null;

    if (draftMap is! Map && thumbnail == null) {
      throw LessonAiException(
        includeText
            ? 'Could not draft the lesson details.'
            : 'Could not generate a lesson thumbnail.',
      );
    }

    final draft = draftMap is Map ? draftMap : const {};
    return LessonAiDraft(
      description: _stringOrNull(draft['description']),
      learningOutcomes: _stringList(draft['learningOutcomes']),
      category: _stringOrNull(draft['category']),
      skillLevel: _stringOrNull(draft['skillLevel']),
      duration: _stringOrNull(draft['duration']),
      lessonType: _stringOrNull(draft['lessonType']),
      learningMaterials: _stringList(draft['learningMaterials']),
      thumbnailBytes: thumbnail?.bytes,
      thumbnailMimeType: thumbnail?.mimeType,
      thumbnailError: _stringOrNull(body['thumbnailError']),
    );
  }

  static Map<String, dynamic> _decodeBody(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return {};
  }

  static String _candidateText(Map<String, dynamic> data) {
    final candidates = data['candidates'];
    if (candidates is! List || candidates.isEmpty) return '';
    final content = candidates.first;
    if (content is! Map) return '';
    final parts = content['content'];
    if (parts is! Map) return '';
    final list = parts['parts'];
    if (list is! List) return '';
    final buffer = StringBuffer();
    for (final part in list) {
      if (part is Map && part['text'] != null) {
        buffer.write(part['text']);
      }
    }
    return buffer.toString();
  }

  static ({Uint8List bytes, String mimeType})? _candidateImage(
    Map<String, dynamic> data,
  ) {
    final candidates = data['candidates'];
    if (candidates is! List || candidates.isEmpty) return null;
    final content = candidates.first;
    if (content is! Map) return null;
    final body = content['content'];
    if (body is! Map) return null;
    final list = body['parts'];
    if (list is! List) return null;
    for (final part in list) {
      if (part is! Map) continue;
      final inline = part['inlineData'] ?? part['inline_data'];
      if (inline is! Map) continue;
      final decoded = _decodeThumbnail(inline);
      if (decoded != null) return decoded;
    }
    return null;
  }

  static Map<String, dynamic> _extractJson(String rawText) {
    final clean = rawText
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();
    try {
      final decoded = jsonDecode(clean);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      final start = clean.indexOf('{');
      final end = clean.lastIndexOf('}');
      if (start >= 0 && end > start) {
        final decoded = jsonDecode(clean.substring(start, end + 1));
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      }
    }
    throw LessonAiException('Could not read the AI lesson draft.');
  }

  static String _pick(Object? value, List<String> allowed, String fallback) {
    final text = value?.toString().trim().toLowerCase() ?? '';
    for (final item in allowed) {
      if (item.toLowerCase() == text) return item;
    }
    return fallback;
  }

  static String? _stringOrNull(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static List<String> _stringList(Object? value) {
    final Iterable<String> source;
    if (value is List) {
      source = value.map((item) => item.toString());
    } else if (value is String) {
      source = value.split('\n');
    } else {
      return const [];
    }
    return source
        .map((item) => item.replaceFirst(RegExp(r'^[-*•\d.)\s]+'), '').trim())
        .where((item) {
          if (item.isEmpty) return false;
          return !item.toLowerCase().startsWith('http://') &&
              !item.toLowerCase().startsWith('https://');
        })
        .toList();
  }

  static ({Uint8List bytes, String mimeType})? _decodeThumbnail(Map map) {
    final mimeType = (map['mimeType'] ?? map['mime_type'] ?? 'image/png')
        .toString();
    var payload = (map['data'] ?? '').toString().trim();
    final comma = payload.indexOf(',');
    if (payload.startsWith('data:') && comma != -1) {
      payload = payload.substring(comma + 1);
    }
    payload = payload.replaceAll(RegExp(r'\s'), '');
    if (payload.isEmpty) return null;
    try {
      final bytes = base64Decode(payload);
      if (bytes.isEmpty) return null;
      return (bytes: bytes, mimeType: mimeType);
    } catch (_) {
      return null;
    }
  }
}
