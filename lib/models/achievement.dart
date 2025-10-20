import 'package:flutter/foundation.dart';

enum AchievementType { streak, accuracy, completion, speed, mastery }

@immutable
class Achievement {
  final String id;
  final String name;
  final String description;
  final AchievementType type;
  final DateTime earnedAt;
  final bool isNew;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.earnedAt,
    this.isNew = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'type': type.name,
    'earnedAt': earnedAt.toIso8601String(),
    'isNew': isNew,
  };

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    type: AchievementType.values.firstWhere(
      (e) => e.name == json['type'] as String,
    ),
    earnedAt: DateTime.parse(json['earnedAt'] as String),
    isNew: json['isNew'] as bool? ?? false,
  );
}
