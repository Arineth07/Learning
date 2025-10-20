import 'package:hive/hive.dart';
import 'enums.dart';

part 'topic.g.dart';

@HiveType(typeId: 11)
class Topic {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String subjectId;

  @HiveField(4)
  final List<String> prerequisiteTopicIds;

  @HiveField(5)
  final List<String> questionIds;

  @HiveField(6)
  final DifficultyLevel difficulty;

  @HiveField(7)
  final int estimatedDurationMinutes;

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  final DateTime updatedAt;

  @HiveField(10)
  final bool isActive;

  Topic({
    required this.id,
    required this.name,
    required this.description,
    required this.subjectId,
    required this.difficulty,
    this.estimatedDurationMinutes = 30,
    List<String>? prerequisiteTopicIds,
    List<String>? questionIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isActive = true,
  }) : prerequisiteTopicIds = prerequisiteTopicIds ?? [],
       questionIds = questionIds ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  List<String> get prerequisites => prerequisiteTopicIds;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'subjectId': subjectId,
    'prerequisiteTopicIds': prerequisiteTopicIds,
    'questionIds': questionIds,
    'difficulty': difficulty.toJson(),
    'estimatedDurationMinutes': estimatedDurationMinutes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'isActive': isActive,
  };

  factory Topic.fromJson(Map<String, dynamic> json) => Topic(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    subjectId: json['subjectId'] as String,
    prerequisiteTopicIds:
        (json['prerequisiteTopicIds'] as List?)?.cast<String>() ?? [],
    questionIds: (json['questionIds'] as List?)?.cast<String>() ?? [],
    difficulty: DifficultyLevel.fromJson(json['difficulty'] as String),
    estimatedDurationMinutes: json['estimatedDurationMinutes'] as int? ?? 30,
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : null,
    updatedAt: json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'] as String)
        : null,
    isActive: json['isActive'] as bool? ?? true,
  );
}
