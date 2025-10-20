import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../repositories/content_repository.dart';
import '../repositories/user_progress_repository.dart';
import '../services/recommendation_service.dart';
import '../utils/result.dart';

class TopicListWidget extends StatelessWidget {
  final String subjectId;
  final Function(Topic) onTopicSelected;

  const TopicListWidget({
    super.key,
    required this.subjectId,
    required this.onTopicSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer3<
      ContentRepository,
      RecommendationService,
      UserProgressRepository
    >(
      builder: (context, contentRepo, recommendationService, progressRepo, child) {
        return FutureBuilder<Result<List<Topic>>>(
          future: contentRepo.getTopicsBySubjectId(subjectId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return const Center(child: Text('Failed to load topics'));
            }

            return snapshot.data!.fold((topics) {
              if (topics.isEmpty) {
                return Center(
                  child: Text(
                    'No topics available for this subject',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                );
              }

              return FutureBuilder<Result<List<UserProgress>>>(
                future: progressRepo.getBySubjectId('demo_user', subjectId),
                builder: (context, progressSnapshot) {
                  final Map<String, UserProgress> progressByTopic = {};
                  if (progressSnapshot.hasData) {
                    progressSnapshot.data?.fold((progress) {
                      for (var p in progress) {
                        progressByTopic[p.topicId] = p;
                      }
                    }, (_) {});
                  }

                  return ListView.builder(
                    itemCount: topics.length,
                    itemBuilder: (context, index) {
                      final topic = topics[index];
                      final progress = progressByTopic[topic.id];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: InkWell(
                          onTap: () => onTopicSelected(topic),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  topic.name,
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.titleMedium,
                                                ),
                                              ),
                                              if (progress != null) ...[
                                                Chip(
                                                  label: Text(
                                                    '${(progress.averageScore * 100).toInt()}%',
                                                  ),
                                                  backgroundColor:
                                                      _getMasteryColor(
                                                        progress.averageScore,
                                                      ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            topic.description,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      _getDifficultyIcon(topic.difficulty),
                                      color: _getDifficultyColor(
                                        topic.difficulty,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    if (progress == null)
                                      const Chip(
                                        label: Text('New'),
                                        backgroundColor: Colors.blue,
                                      )
                                    else if (progress.averageScore < 0.6)
                                      const Chip(
                                        label: Text('Knowledge Gap'),
                                        backgroundColor: Colors.orange,
                                      ),
                                    if (progress?.needsReview ?? false)
                                      const Chip(
                                        label: Text('Review Due'),
                                        backgroundColor: Colors.purple,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () => onTopicSelected(topic),
                                      icon: const Icon(Icons.school),
                                      label: Text(
                                        progress == null
                                            ? 'Start Learning'
                                            : 'Practice',
                                      ),
                                    ),
                                    if (progress != null) ...[
                                      const SizedBox(width: 8),
                                      TextButton.icon(
                                        onPressed: () => onTopicSelected(topic),
                                        icon: const Icon(Icons.refresh),
                                        label: const Text('Review'),
                                      ),
                                    ],
                                  ],
                                ),
                                if (topic.prerequisites.isNotEmpty) ...[
                                  const Divider(),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Prerequisites:',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    topic.prerequisites.join(', '),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            }, (failure) => Center(child: Text('Error: ${failure.message}')));
          },
        );
      },
    );
  }

  Color _getMasteryColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    return Colors.red;
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
        return Icons.stars;
    }
  }

  Color _getDifficultyColor(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.beginner:
        return Colors.green;
      case DifficultyLevel.intermediate:
        return Colors.orange;
      case DifficultyLevel.advanced:
        return Colors.red;
      case DifficultyLevel.expert:
        return Colors.purple;
    }
  }
}
