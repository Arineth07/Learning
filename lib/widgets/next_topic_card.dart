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
                        Text(
                          ExpansionTile(
                            title: Text('Score Breakdown'),
                            children: [
                              ListTile(
                                title: Text('Composite'),
                                trailing: Text('${topic.compositeScore.toStringAsFixed(1)}'),
                              ),
                              ListTile(
                                title: Text('Urgency'),
                                trailing: Text('${topic.urgencyScore.toStringAsFixed(1)}'),
                              ),
                              ListTile(
                                title: Text('Readiness'),
                                trailing: Text('${topic.readinessScore.toStringAsFixed(1)}'),
                              ),
                              ListTile(
                                title: Text('Impact'),
                                trailing: Text('${topic.impactScore.toStringAsFixed(1)}'),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton(
                                onPressed: () => onStartPractice(topic),
                                child: const Text('Start Practice'),
                              ),
                            ],
                          ),
                            ListTile(
                              title: const Text('Urgency'),
                              trailing: Text(
                                '${(data.urgencyScore * 100).toStringAsFixed(0)}%',
                              ),
                            ),
                            ListTile(
                              title: const Text('Readiness'),
                              trailing: Text(
                                '${(data.readinessScore * 100).toStringAsFixed(0)}%',
                              ),
                            ),
                            ListTile(
                              title: const Text('Impact'),
                              trailing: Text(
                                '${(data.impactScore * 100).toStringAsFixed(0)}%',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
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
