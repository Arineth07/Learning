import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../repositories/content_repository.dart';
import '../repositories/user_progress_repository.dart';
import '../services/recommendation_service.dart';
import '../utils/result.dart';

class SubjectSelectorWidget extends StatefulWidget {
  final Function(Subject) onSubjectSelected;
  final String selectedSubjectId;

  const SubjectSelectorWidget({
    super.key,
    required this.onSubjectSelected,
    required this.selectedSubjectId,
  });

  @override
  State<SubjectSelectorWidget> createState() => _SubjectSelectorWidgetState();
}

class _SubjectSelectorWidgetState extends State<SubjectSelectorWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer3<
      ContentRepository,
      RecommendationService,
      UserProgressRepository
    >(
      builder:
          (context, contentRepo, recommendationService, progressRepo, child) {
            return FutureBuilder<Result<List<Subject>>>(
              future: contentRepo.getAllSubjects(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Failed to load subjects',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  );
                }

                final result = snapshot.data;
                if (result == null) {
                  return Center(
                    child: Text(
                      'No subjects available',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  );
                }

                return result.fold(
                  (subjects) => _buildSubjectList(subjects),
                  (failure) => Center(
                    child: Text(
                      'Error: ${failure.message}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                );
              },
            );
          },
    );
  }

  Widget _buildSubjectList(List<Subject> subjects) {
    return Consumer<UserProgressRepository>(
      builder: (context, progressRepo, child) {
        return FutureBuilder<Result<Map<String, double>>>(
          future: progressRepo.getSubjectAverages('demo_user'),
          builder: (context, snapshot) {
            final Map<String, double> averages =
                snapshot.data?.fold((averages) => averages, (_) => {}) ?? {};

            return ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                final subject = subjects[index];
                final isSelected = subject.id == widget.selectedSubjectId;
                final progress = averages[subject.id] ?? 0.0;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ChoiceChip(
                        label: Text(subject.name),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            widget.onSubjectSelected(subject);
                          }
                        },
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : null,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        backgroundColor: Colors.grey[200],
                        selectedColor: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 60,
                        height: 4,
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey[300],
                          color: _getProgressColor(progress),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 0.8) return Colors.green;
    if (progress >= 0.5) return Colors.orange;
    return Colors.red;
  }
}
