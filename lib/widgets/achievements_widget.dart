import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/result.dart';

class AchievementsWidget extends StatelessWidget {
  final String userId;

  const AchievementsWidget({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Achievements', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            FutureBuilder<Result<List<Achievement>>>(
              // TODO: Implement proper achievements system
              future: Future.value(const Result.success(<Achievement>[])),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Failed to load achievements'),
                  );
                }

                final result = snapshot.data;
                if (result == null) {
                  return const Center(
                    child: Text('No achievement data available'),
                  );
                }

                return result.fold(
                  (achievements) {
                    if (achievements.isEmpty) {
                      return const Center(
                        child: Text(
                          'Complete learning sessions to earn achievements!',
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: achievements.length,
                      itemBuilder: (context, index) {
                        final achievement = achievements[index];
                        return ListTile(
                          leading: Icon(
                            _getAchievementIcon(achievement.type),
                            color: _getAchievementColor(achievement.type),
                          ),
                          title: Text(achievement.name),
                          subtitle: Text(achievement.description),
                          trailing: achievement.isNew
                              ? Chip(
                                  label: const Text('New!'),
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                                )
                              : null,
                        );
                      },
                    );
                  },
                  (failure) =>
                      Center(child: Text('Error: ${failure.message}')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAchievementIcon(AchievementType type) {
    switch (type) {
      case AchievementType.streak:
        return Icons.local_fire_department;
      case AchievementType.accuracy:
        return Icons.trending_up;
      case AchievementType.completion:
        return Icons.check_circle;
      case AchievementType.speed:
        return Icons.speed;
      case AchievementType.mastery:
        return Icons.star;
    }
  }

  Color _getAchievementColor(AchievementType type) {
    switch (type) {
      case AchievementType.streak:
        return Colors.orange;
      case AchievementType.accuracy:
        return Colors.green;
      case AchievementType.completion:
        return Colors.blue;
      case AchievementType.speed:
        return Colors.purple;
      case AchievementType.mastery:
        return Colors.amber;
    }
  }
}
