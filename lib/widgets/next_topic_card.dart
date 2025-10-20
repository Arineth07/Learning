import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/recommendation_service.dart';
import '../utils/result.dart';
import '../screens/question_screen_arguments.dart';

class NextTopicCard extends StatelessWidget {
  final String userId;
  final String subjectId;

  const NextTopicCard({
    super.key,
    required this.userId,
    required this.subjectId,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<RecommendationService>(
      builder: (context, service, child) {
        if (!service.isInitialized) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text('Loading recommendations...')),
            ),
          );
        }

        return FutureBuilder<Result<TopicRecommendation>>(
          future: service.getNextTopicRecommendation(userId, subjectId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return const SizedBox.shrink();
            }

            return snapshot.data!.fold(
              (data) => Card(
                child: InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/question',
                      arguments: QuestionScreenArguments(
                        topicId: data.topicId,
                        difficulty: data.recommendedDifficulty,
                        questionCount: 5,
                        usePersonalizedQuestions: true,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recommended Next Topic',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          data.topicName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),

                        // Recommendation reason
                        if (data.recommendationReason.isNotEmpty) ...[
                          Text(
                            data.recommendationReason,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Difficulty and estimated time
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _getDifficultyIcon(data.recommendedDifficulty),
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  data.recommendedDifficulty.name.toUpperCase(),
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ],
                            ),
                            Text(
                              '~${data.estimatedMinutes} min',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Status badges
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (data.hasKnowledgeGap) Chip(
                              label: const Text('Knowledge Gap'),
                              labelStyle: Theme.of(context).textTheme.labelSmall,
                              backgroundColor: Theme.of(context).colorScheme.errorContainer,
                            ),
                            if (data.isOverdueForReview) Chip(
                              label: const Text('Review Needed'),
                              labelStyle: Theme.of(context).textTheme.labelSmall,
                              backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                            ),
                            if (data.hasUnmetPrerequisites) Chip(
                              label: const Text('Prerequisites Required'),
                              labelStyle: Theme.of(context).textTheme.labelSmall,
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Expandable score breakdown
                        ExpansionTile(
                          title: Text('Score Breakdown', style: Theme.of(context).textTheme.titleSmall),
                          initiallyExpanded: false,
                          children: [
                            ListTile(
                              title: const Text('Overall Score'),
                              trailing: Text(
                                '${(data.compositeScore * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  color: data.compositeScore >= 0.7
                                      ? Theme.of(context).colorScheme.error
                                      : data.compositeScore >= 0.5
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            ListTile(
                              title: const Text('Urgency'),
                              subtitle: const Text('How soon this needs attention'),
                              trailing: Text(
                                '${(data.urgencyScore * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  color: data.urgencyScore >= 0.7
                                      ? Theme.of(context).colorScheme.error
                                      : data.urgencyScore >= 0.5
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            ListTile(
                              title: const Text('Readiness'),
                              subtitle: const Text('Prerequisites completion'),
                              trailing: Text(
                                '${(data.readinessScore * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  color: data.readinessScore >= 0.7
                                      ? Theme.of(context).colorScheme.error
                                      : data.readinessScore >= 0.5
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            ListTile(
                              title: const Text('Impact'),
                              subtitle: const Text('Learning path importance'),
                              trailing: Text(
                                '${(data.impactScore * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  color: data.impactScore >= 0.7
                                      ? Theme.of(context).colorScheme.error
                                      : data.impactScore >= 0.5
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            ListTile(
                              title: const Text('Engagement'),
                              subtitle: const Text('Recent activity level'),
                              trailing: Text(
                                '${(data.engagementScore * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  color: data.engagementScore >= 0.7
                                      ? Theme.of(context).colorScheme.error
                                      : data.engagementScore >= 0.5
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Action button (kept as originally implemented)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/question',
                                  arguments: QuestionScreenArguments(
                                    topicId: data.topicId,
                                    difficulty: data.recommendedDifficulty,
                                    questionCount: 5,
                                    usePersonalizedQuestions: true,
                                  ),
                                );
                              },
                              child: const Text('Start Practice'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              (failure) => const SizedBox.shrink(),
            );
          },
        );
      },
    );
  }

  IconData _getDifficultyIcon(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.beginner:
        return Icons.star_border;
      case DifficultyLevel.intermediate:
        return Icons.star_half;
      case DifficultyLevel.advanced:
        return Icons.star;
      case DifficultyLevel.expert:
        return Icons.workspace_premium;
    }
  }
}
