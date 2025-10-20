import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../repositories/learning_session_repository.dart';
import '../repositories/content_repository.dart';
import '../screens/question_screen_arguments.dart';
import '../utils/result.dart';

class LearningPathStepCard extends StatelessWidget {
  final String topicId;
  final String userId;

  const LearningPathStepCard({
    super.key,
    required this.topicId,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Consumer2<LearningSessionRepository, ContentRepository>(
        builder: (context, sessionRepo, contentRepo, child) {
          return FutureBuilder<Result<Topic>>(
            future: contentRepo.getTopicById(topicId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const SizedBox.shrink();
              }

              final result = snapshot.data;
              if (result == null) {
                return const SizedBox.shrink();
              }

              return result.fold(
                (topic) => InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/question',
                      arguments: QuestionScreenArguments(
                        topicId: topic.id,
                        difficulty: DifficultyLevel.beginner,
                        questionCount: 5,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    topic.name,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
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
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        const SizedBox(height: 16),
                        FutureBuilder<Result<double>>(
                          future: sessionRepo.getTopicCompletionRate(
                            userId,
                            topicId,
                          ),
                          builder: (context, progressSnapshot) {
                            if (progressSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const LinearProgressIndicator();
                            }

                            final result = progressSnapshot.data;
                            if (result == null) {
                              return const LinearProgressIndicator();
                            }

                            return result.fold(
                              (progress) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  LinearProgressIndicator(value: progress),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${(progress * 100).toInt()}% Complete',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              (failure) => const LinearProgressIndicator(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                (failure) => const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }
}
