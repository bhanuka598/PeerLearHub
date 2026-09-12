import 'package:cloud_firestore/cloud_firestore.dart';

enum LessonCategory {
  programming,
  design,
  business,
  languages,
  music,
  photography,
  cooking,
  other,
}

enum SkillLevel {
  beginner,
  intermediate,
  advanced,
}

enum LessonType {
  online,
  inPerson,
  both,
}

enum LessonStatus {
  draft,
  active,
  inactive,
}

enum ExchangeType {
  free,
  paid,
  skillExchange,
}

class LessonAvailability {
  const LessonAvailability({
    required this.availableDays,
    required this.preferredTime,
  });

  final List<String> availableDays;
  final String preferredTime;

  LessonAvailability copyWith({
    List<String>? availableDays,
    String? preferredTime,
  }) {
    return LessonAvailability(
      availableDays: availableDays ?? this.availableDays,
      preferredTime: preferredTime ?? this.preferredTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'availableDays': availableDays,
      'preferredTime': preferredTime,
    };
  }

  factory LessonAvailability.fromMap(Map<String, dynamic> map) {
    return LessonAvailability(
      availableDays: List<String>.from(map['availableDays'] as List? ?? []),
      preferredTime: map['preferredTime'] as String? ?? '',
    );
  }
}

class Lesson {
  const Lesson({
    required this.id,
    required this.providerId,
    required this.title,
    required this.description,
    required this.category,
    required this.skillLevel,
    required this.duration,
    required this.lessonType,
    required this.availability,
    required this.location,
    required this.isFree,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.price,
    this.imageUrl,
    this.learningOutcomes = const [],
    this.exchangeType = ExchangeType.paid,
    this.learningMaterials = const [],
  });

  final String id;
  final String providerId;
  final String title;
  final String description;
  final LessonCategory category;
  final SkillLevel skillLevel;
  final String duration;
  final LessonType lessonType;
  final LessonAvailability availability;
  final String location;
  final double? price;
  final bool isFree;
  final LessonStatus status;
  final String? imageUrl;
  final List<String> learningOutcomes;
  final ExchangeType exchangeType;
  final List<String> learningMaterials;
  final DateTime createdAt;
  final DateTime updatedAt;

  Lesson copyWith({
    String? id,
    String? providerId,
    String? title,
    String? description,
    LessonCategory? category,
    SkillLevel? skillLevel,
    String? duration,
    LessonType? lessonType,
    LessonAvailability? availability,
    String? location,
    double? price,
    bool? isFree,
    LessonStatus? status,
    String? imageUrl,
    List<String>? learningOutcomes,
    ExchangeType? exchangeType,
    List<String>? learningMaterials,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearPrice = false,
    bool clearImageUrl = false,
  }) {
    return Lesson(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      skillLevel: skillLevel ?? this.skillLevel,
      duration: duration ?? this.duration,
      lessonType: lessonType ?? this.lessonType,
      availability: availability ?? this.availability,
      location: location ?? this.location,
      price: clearPrice ? null : (price ?? this.price),
      isFree: isFree ?? this.isFree,
      status: status ?? this.status,
      imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
      learningOutcomes: learningOutcomes ?? this.learningOutcomes,
      exchangeType: exchangeType ?? this.exchangeType,
      learningMaterials: learningMaterials ?? this.learningMaterials,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'providerId': providerId,
      'title': title,
      'description': description,
      'category': category.name,
      'skillLevel': skillLevel.name,
      'duration': duration,
      'lessonType': lessonType.name,
      'availability': availability.toMap(),
      'location': location,
      'price': price,
      'isFree': isFree,
      'status': status.name,
      'imageUrl': imageUrl,
      'learningOutcomes': learningOutcomes,
      'exchangeType': exchangeType.name,
      'learningMaterials': learningMaterials,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'providerId': providerId,
      'title': title,
      'description': description,
      'category': category.name,
      'skillLevel': skillLevel.name,
      'duration': duration,
      'lessonType': lessonType.name,
      'availability': availability.toMap(),
      'location': location,
      'price': price,
      'isFree': isFree,
      'status': status.name,
      'imageUrl': imageUrl,
      'learningOutcomes': learningOutcomes,
      'exchangeType': exchangeType.name,
      'learningMaterials': learningMaterials,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Lesson.fromMap(Map<String, dynamic> map) {
    return Lesson(
      id: map['id'] as String,
      providerId: map['providerId'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      category: LessonCategory.values.byName(map['category'] as String),
      skillLevel: SkillLevel.values.byName(map['skillLevel'] as String),
      duration: map['duration'] as String,
      lessonType: LessonType.values.byName(map['lessonType'] as String),
      availability: LessonAvailability.fromMap(
        Map<String, dynamic>.from(map['availability'] as Map),
      ),
      location: map['location'] as String,
      price: (map['price'] as num?)?.toDouble(),
      isFree: map['isFree'] as bool? ?? true,
      status: LessonStatus.values.byName(map['status'] as String),
      imageUrl: map['imageUrl'] as String?,
      learningOutcomes: List<String>.from(map['learningOutcomes'] as List? ?? []),
      exchangeType: ExchangeType.values.firstWhere(
        (e) => e.name == map['exchangeType'],
        orElse: () => ExchangeType.paid,
      ),
      learningMaterials:
          List<String>.from(map['learningMaterials'] as List? ?? []),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  factory Lesson.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Lesson.fromDocData(doc.id, data);
  }

  factory Lesson.fromDocData(String id, Map<String, dynamic> data) {
    return Lesson(
      id: id,
      providerId: data['providerId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: LessonCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => LessonCategory.other,
      ),
      skillLevel: SkillLevel.values.firstWhere(
        (e) => e.name == data['skillLevel'],
        orElse: () => SkillLevel.beginner,
      ),
      duration: data['duration'] as String? ?? '',
      lessonType: LessonType.values.firstWhere(
        (e) => e.name == data['lessonType'],
        orElse: () => LessonType.online,
      ),
      availability: LessonAvailability.fromMap(
        Map<String, dynamic>.from(data['availability'] as Map? ?? {}),
      ),
      location: data['location'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble(),
      isFree: data['isFree'] as bool? ?? true,
      status: LessonStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => LessonStatus.draft,
      ),
      imageUrl: data['imageUrl'] as String?,
      learningOutcomes:
          List<String>.from(data['learningOutcomes'] as List? ?? []),
      exchangeType: ExchangeType.values.firstWhere(
        (e) => e.name == data['exchangeType'],
        orElse: () => ExchangeType.paid,
      ),
      learningMaterials:
          List<String>.from(data['learningMaterials'] as List? ?? []),
      createdAt: _parseDate(data['createdAt']),
      updatedAt: _parseDate(data['updatedAt']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }
}
