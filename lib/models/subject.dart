import 'package:hive/hive.dart';
import 'enums.dart';

part 'subject.g.dart';

@HiveType(typeId: 10)
class Subject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final SubjectCategory category;

  @HiveField(4)
  final List<String> topicIds;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final DateTime updatedAt;

  @HiveField(7)
  final bool isActive;

  Subject({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    List<String>? topicIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isActive = true,
  }) : topicIds = topicIds ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'category': category.toJson(),
    'topicIds': topicIds,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'isActive': isActive,
  };

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    category: SubjectCategory.fromJson(json['category'] as String),
    topicIds: (json['topicIds'] as List?)?.cast<String>() ?? [],
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : null,
    updatedAt: json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'] as String)
        : null,
    isActive: json['isActive'] as bool? ?? true,
  );
}
