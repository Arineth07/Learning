import 'package:hive/hive.dart';
import 'enums.dart';

part 'question.g.dart';

@HiveType(typeId: 12)
class Question {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String text;

  @HiveField(2)
  final List<String> options;

  @HiveField(3)
  final String correctAnswer;

  @HiveField(4)
  final String explanation;

  @HiveField(5)
  final String topicId;

  @HiveField(6)
  final DifficultyLevel difficulty;

  @HiveField(7)
  final QuestionType type;

  @HiveField(8)
  final int estimatedTimeSeconds;

  @HiveField(9)
  final int points;

  @HiveField(10)
  final DateTime createdAt;

  @HiveField(11)
  final DateTime updatedAt;

  @HiveField(12)
  final bool isActive;

  Question({
    required this.id,
    required this.text,
    required this.correctAnswer,
    required this.explanation,
    required this.topicId,
    required this.difficulty,
    required this.type,
    List<String>? options,
    this.estimatedTimeSeconds = 60,
    this.points = 10,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isActive = true,
  }) : options = options ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'options': options,
    'correctAnswer': correctAnswer,
    'explanation': explanation,
    'topicId': topicId,
    'difficulty': difficulty.toJson(),
    'type': type.toJson(),
    'estimatedTimeSeconds': estimatedTimeSeconds,
    'points': points,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'isActive': isActive,
  };

  factory Question.fromJson(Map<String, dynamic> json) => Question(
    id: json['id'] as String,
    text: json['text'] as String,
    options: (json['options'] as List?)?.cast<String>() ?? [],
    correctAnswer: json['correctAnswer'] as String,
    explanation: json['explanation'] as String,
    topicId: json['topicId'] as String,
    difficulty: DifficultyLevel.fromJson(json['difficulty'] as String),
    type: QuestionType.fromJson(json['type'] as String),
    estimatedTimeSeconds: json['estimatedTimeSeconds'] as int? ?? 60,
    points: json['points'] as int? ?? 10,
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : null,
    updatedAt: json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'] as String)
        : null,
    isActive: json['isActive'] as bool? ?? true,
  );
}
