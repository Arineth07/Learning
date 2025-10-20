import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/user_progress_repository.dart';
import '../models/models.dart';
import '../utils/result.dart';

class WelcomeCard extends StatelessWidget {
  final String userId;
        child: FutureBuilder<List<dynamic>>(
          future: Future.wait([
            LearningSessionRepository.getTotalSessionCount(userId),
            LearningSessionRepository.getAverageAccuracy(userId),
            LearningSessionRepository.getTotalStudyTimeMinutes(userId),
          ]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }
            final totalSessions = snapshot.data?[0] ?? 0;
            final avgAccuracy = snapshot.data?[1] ?? 0.0;
            final studyMinutes = snapshot.data?[2] ?? 0;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome back, $userName!', style: Theme.of(context).textTheme.headline6),
                    const SizedBox(height: 8),
                    Text('Total Sessions: $totalSessions'),
                    Text('Average Accuracy: ${avgAccuracy.toStringAsFixed(1)}%'),
                    Text('Total Study Time: $studyMinutes min'),
                    const SizedBox(height: 8),
                    Text('Keep up the great work!'),
                  ],
                ),
              ),
            );
          },
        );
                    ],
                  );
                }

                final result = snapshot.data;
                if (result == null) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Welcome to AI Tutor! Ready to start learning?',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  );
                }

                return result.fold(
                  (progressList) {
                    // Get the most recent progress or create a default one
                    UserProgress? latestProgress;
                    if (progressList.isNotEmpty) {
                      // Sort by lastAttemptAt to get the most recent
                      progressList.sort((a, b) => b.lastAttemptAt.compareTo(a.lastAttemptAt));
                      latestProgress = progressList.first;
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 16),
                        if (latestProgress != null) ...[
                          Text(
                            'Last session: ${_formatDate(latestProgress.lastAttemptAt)}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getMotivationalMessage(latestProgress),
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          if (latestProgress.totalAttempts > 0) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Icon(
                                  Icons.local_fire_department,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Accuracy: ${(latestProgress.correctAttempts / latestProgress.totalAttempts * 100).toStringAsFixed(1)}%',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(color: Colors.orange),
                                ),
                              ],
                            ),
                          ],
                        ] else ...[
                          Text(
                            'Welcome to AI Tutor! Ready to start learning?',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ],
                    );
                  },
                  (error) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${error.message}',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(color: Colors.red),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning!';
    } else if (hour < 17) {
      return 'Good afternoon!';
    } else {
      return 'Good evening!';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  String _getMotivationalMessage(UserProgress progress) {
    if (progress.totalAttempts == 0) {
      return 'Welcome! Let\'s start your learning journey.';
    }

    final daysSinceLastSession = DateTime.now()
        .difference(progress.lastAttemptAt)
        .inDays;

    if (daysSinceLastSession == 0) {
      return 'Great work today! Keep the momentum going!';
    } else if (daysSinceLastSession == 1) {
      return 'Welcome back! Ready to continue learning?';
    } else if (daysSinceLastSession <= 3) {
      return 'It\'s been a few days. Let\'s get back to learning!';
    } else {
      return 'We\'ve missed you! Time to jump back in?';
    }
  }
}
