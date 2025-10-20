import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../repositories/learning_session_repository.dart';
import '../../utils/result.dart';

class StudyTimeChart extends StatelessWidget {
  final String userId;
  final int daysToShow;

  const StudyTimeChart({super.key, required this.userId, this.daysToShow = 7});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Study Time by Topic',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: Consumer<LearningSessionRepository>(
                builder: (context, repository, child) {
                  return FutureBuilder<Result<Map<String, Duration>>>(
                    future: repository.getStudyTimeByTopic(userId),
                    builder:
                        (
                          BuildContext context,
                          AsyncSnapshot<Result<Map<String, Duration>>> snapshot,
                        ) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    size: 48,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(height: 16),
                                  Text('Error: ${snapshot.error}'),
                                ],
                              ),
                            );
                          }

                          final result = snapshot.data;
                          if (result == null) {
                            return const Center(
                              child: Text('No data available'),
                            );
                          }

                          return result.fold(
                            (topicMinutes) {
                              if (topicMinutes.isEmpty) {
                                return const Center(
                                  child: Text(
                                    'No study time data available yet',
                                  ),
                                );
                              }

                              final totalMinutes = topicMinutes.values
                                  .fold<int>(
                                    0,
                                    (sum, duration) => sum + duration.inMinutes,
                                  );

                              if (totalMinutes == 0) {
                                return const Center(
                                  child: Text(
                                    'No study time recorded in this period',
                                  ),
                                );
                              }

                              // Convert Duration to minutes for the charts
                              final minutesByTopic =
                                  Map<String, int>.fromEntries(
                                    topicMinutes.entries.map(
                                      (e) => MapEntry(e.key, e.value.inMinutes),
                                    ),
                                  );

                              final sections = _createPieChartSections(
                                minutesByTopic,
                              );
                              final legendItems = _createLegendItems(
                                minutesByTopic,
                              );

                              return Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: PieChart(
                                      PieChartData(
                                        sections: sections,
                                        centerSpaceRadius: 40,
                                        sectionsSpace: 2,
                                        pieTouchData: PieTouchData(
                                          enabled: true,
                                          touchCallback: (event, response) {
                                            // Handle touch events if needed
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 1,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ...legendItems,
                                        const SizedBox(height: 16),
                                        Text(
                                          'Total: ${_formatTotalTime(totalMinutes)}',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                            (error) => Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    size: 48,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(height: 16),
                                  Text('Error: ${error.message}'),
                                ],
                              ),
                            ),
                          );
                        },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _createPieChartSections(
    Map<String, int> topicMinutes,
  ) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.amber,
    ];

    final totalMinutes = topicMinutes.values.fold<int>(
      0,
      (sum, minutes) => sum + minutes,
    );

    var colorIndex = 0;
    return topicMinutes.entries.map((entry) {
      final percentage = (entry.value / totalMinutes) * 100;
      final color = colors[colorIndex % colors.length];
      colorIndex++;

      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  List<Widget> _createLegendItems(Map<String, int> topicMinutes) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.amber,
    ];

    var colorIndex = 0;
    return topicMinutes.entries.map((entry) {
      final color = colors[colorIndex % colors.length];
      colorIndex++;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${entry.key}: ${_formatTotalTime(entry.value)}',
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  String _formatTotalTime(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (hours > 0) {
      return '$hours hr ${remainingMinutes > 0 ? '$remainingMinutes min' : ''}';
    }
    return '$minutes min';
  }
}
