import 'package:flutter/material.dart';
import '../models/models.dart';
import '../widgets/charts/charts.dart';
import '../widgets/connectivity_banner.dart';
import '../widgets/connectivity_indicator.dart';
import '../widgets/sync_status_widget.dart';
import '../widgets/achievements_widget.dart';
import '../widgets/learning_path_step_card.dart';
import '../widgets/next_topic_card.dart';
import '../widgets/subject_selector_widget.dart';
import '../widgets/topic_list_widget.dart';
import '../widgets/welcome_card.dart';
import '../services/recommendation_service.dart';
import '../screens/question_screen_arguments.dart';
import '../models/enums.dart';
import '../utils/result.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  // Use a demo user id for now; this can be wired to auth later
  final String _userId = 'demo_user';
  String _selectedSubjectId = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Tutor'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          // Compact sync status indicator
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: SyncStatusWidget(compact: true),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ConnectivityIndicator(),
          ),
        ],
      ),
      body: Column(
        children: [
          ConnectivityBanner(),
          Expanded(child: _buildSelectedTab()),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Overview'),
          NavigationDestination(
            icon: Icon(Icons.route),
            label: 'Learning Path',
          ),
          NavigationDestination(icon: Icon(Icons.school), label: 'Subjects'),
        ],
      ),
    );
  }

  Widget _buildSelectedTab() {
    switch (_selectedIndex) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildLearningPathTab();
      case 2:
        return _buildSubjectsTab();
      default:
        return _buildOverviewTab();
    }
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome card
            WelcomeCard(userId: _userId),
            const SizedBox(height: 16),

            // Performance and knowledge charts
            PerformanceTrendChart(
              userId: _userId,
              subjectId: _selectedSubjectId.isEmpty
                  ? 'mathematics'
                  : _selectedSubjectId,
            ),
            const SizedBox(height: 16),
            KnowledgeGapsChart(
              userId: _userId,
              subjectId: _selectedSubjectId.isEmpty ? null : _selectedSubjectId,
            ),
            const SizedBox(height: 16),

            // Learning pace and study time
            LearningPaceChart(userId: _userId),
            const SizedBox(height: 16),
            StudyTimeChart(userId: _userId),
            const SizedBox(height: 16),

            // Achievements
            AchievementsWidget(userId: _userId),
          ],
        ),
      ),
    );
  }

  Widget _buildLearningPathTab() {
    // Use RecommendationService to generate a personalized learning path
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: FutureBuilder<Result<LearningPath>>(
        future: RecommendationService.instance.generateLearningPath(
          _userId,
          _selectedSubjectId.isEmpty ? 'mathematics' : _selectedSubjectId,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Text(
                'Failed to generate learning path',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }

          final result = snapshot.data!;
          return result.fold(
            (path) {
              final steps = path.steps;
              return ListView.builder(
                itemCount: steps.length + 1,
                itemBuilder: (context, index) {
                  if (index < steps.length) {
                    final step = steps[index];
                    return LearningPathStepCard(
                      topicId: (step as dynamic).topicId as String,
                      userId: _userId,
                    );
                  }
                  // After steps, show next topic card
                  return NextTopicCard(
                    userId: _userId,
                    subjectId: _selectedSubjectId.isEmpty
                        ? 'mathematics'
                        : _selectedSubjectId,
                  );
                },
              );
            },
            (failure) {
              return Center(child: Text('Error: ${failure.message}'));
            },
          );
        },
      ),
    );
  }

  Widget _buildSubjectsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Subject Areas',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),

          // Subject selector - updates selectedSubjectId
          SizedBox(
            height: 56,
            child: SubjectSelectorWidget(
              selectedSubjectId: _selectedSubjectId,
              onSubjectSelected: (subject) {
                setState(() {
                  _selectedSubjectId = subject.id;
                });
              },
            ),
          ),
          const SizedBox(height: 16),

          // Topic list for selected subject
          Expanded(
            child: _selectedSubjectId.isEmpty
                ? Center(
                    child: Text(
                      'Please select a subject',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  )
                : TopicListWidget(
                    subjectId: _selectedSubjectId,
                    onTopicSelected: (topic) {
                      // Navigate to question screen for the selected topic
                      Navigator.pushNamed(
                        context,
                        '/question',
                        arguments: QuestionScreenArguments(
                          topicId: topic.id,
                          difficulty: DifficultyLevel.beginner,
                          questionCount: 10,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Legacy helper cards removed in favor of new dashboard widgets
}
