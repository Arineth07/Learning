import 'package:hive/hive.dart';
import 'enums.dart';

part 'knowledge_gap.g.dart';

@HiveType(typeId: 15)
class KnowledgeGap {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String topicId;

  @HiveField(3)
  final String description;

  @HiveField(4)
  final GapSeverity severity;

  @HiveField(5)
  final List<String> relatedTopicIds;

  @HiveField(6)
  final List<String> recommendedQuestionIds;

  @HiveField(7)
  final bool isResolved;

  @HiveField(8)
  final DateTime identifiedAt;

  @HiveField(9)
  final DateTime? resolvedAt;

  @HiveField(10)
  final DateTime createdAt;

  @HiveField(11)
  final DateTime updatedAt;

  KnowledgeGap({
    required this.id,
    required this.userId,
    required this.topicId,
    required this.description,
    required this.severity,
    List<String>? relatedTopicIds,
    List<String>? recommendedQuestionIds,
    this.isResolved = false,
    DateTime? identifiedAt,
    this.resolvedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : relatedTopicIds = relatedTopicIds ?? [],
       recommendedQuestionIds = recommendedQuestionIds ?? [],
       identifiedAt = identifiedAt ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'topicId': topicId,
    'description': description,
    'severity': severity.toJson(),
    'relatedTopicIds': relatedTopicIds,
    'recommendedQuestionIds': recommendedQuestionIds,
    'isResolved': isResolved,
    'identifiedAt': identifiedAt.toIso8601String(),
    'resolvedAt': resolvedAt?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory KnowledgeGap.fromJson(Map<String, dynamic> json) => KnowledgeGap(
    id: json['id'] as String,
    userId: json['userId'] as String,
    topicId: json['topicId'] as String,
    description: json['description'] as String,
    severity: GapSeverity.fromJson(json['severity'] as String),
    relatedTopicIds: (json['relatedTopicIds'] as List?)?.cast<String>() ?? [],
    recommendedQuestionIds:
        (json['recommendedQuestionIds'] as List?)?.cast<String>() ?? [],
    isResolved: json['isResolved'] as bool? ?? false,
    identifiedAt: json['identifiedAt'] != null
        ? DateTime.parse(json['identifiedAt'] as String)
        : null,
    resolvedAt: json['resolvedAt'] != null
        ? DateTime.parse(json['resolvedAt'] as String)
        : null,
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : null,
    updatedAt: json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'] as String)
        : null,
  );
}
