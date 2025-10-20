import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/adaptive_learning_service.dart';
import '../../models/models.dart';
import '../../utils/constants.dart';
import '../../utils/result.dart';

class LearningPaceChart extends StatelessWidget {
  final String userId;
  final String? subjectId;

  const LearningPaceChart({super.key, required this.userId, this.subjectId});

  @override
  Widget build(BuildContext context) {
    final subj = subjectId ?? 'mathematics';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Learning Pace',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    // parent rebuild is required to refresh; using Provider listeners would be better
                    // For now, trigger a rebuild by calling setState at parent or rely on consumers
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: 200,
              child: Consumer<AdaptiveLearningService>(
                builder: (context, service, child) {
                  if (!service.isInitialized) {
                    return const Center(
                      child: Text('Learning service not initialized'),
                    );
                  }

                  return FutureBuilder<
                    Result<Map<String, LearningPaceInsights>>
                  >(
                    future: service.analyzeLearningPaceForAllTopics(
                      userId,
                      subj,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError || snapshot.data == null) {
                        return const Center(
                          child: Text('Failed to load learning pace data'),
                        );
                      }

                      return snapshot.data!.fold(
                        (insightsMap) {
                          if (insightsMap.isEmpty) {
                            return const Center(
                              child: Text(
                                'No learning pace data available yet',
                              ),
                            );
                          }

                          // Convert map to list of entries and sort by paceRatio descending
                          final entries =
                              insightsMap.entries.map((e) => e.value).toList()
                                ..sort(
                                  (a, b) => b.paceRatio.compareTo(a.paceRatio),
                                );

                          final display = entries.take(10).toList();
                          final maxVal =
                              (display
                                          .map((e) => e.paceRatio)
                                          .fold<double>(
                                            0.0,
                                            (p, n) => n > p ? n : p,
                                          ) *
                                      1.2)
                                  .clamp(1.0, 3.0);

                          // Build bar groups
                          final barGroups = List.generate(display.length, (i) {
                            final e = display[i];
                            final value = e.paceRatio;
                            Color color;
                            if (value <
                                AdaptiveLearningConstants.paceFastThreshold) {
                              color = Colors.green;
                            } else if (value >
                                AdaptiveLearningConstants.paceSlowThreshold) {
                              color = Colors.red;
                            } else {
                              color = Colors.orange;
                            }

                            return BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: value,
                                  color: color,
                                  width: 18,
                                ),
                              ],
                              showingTooltipIndicators: [0],
                            );
                          });

                          return RotatedBox(
                            quarterTurns: 3,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: maxVal,
                                barTouchData: BarTouchData(
                                  enabled: true,
                                  touchTooltipData: BarTouchTooltipData(
                                    getTooltipItem:
                                        (group, groupIndex, rod, rodIndex) {
                                          final idx = group.x.toInt();
                                          final item = display[idx];
                                          return BarTooltipItem(
                                            '${item.topicName}\nPace: ${item.paceCategory} (${item.paceRatio.toStringAsFixed(2)}x)',
                                            const TextStyle(
                                              color: Colors.white,
                                            ),
                                          );
                                        },
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 120,
                                      getTitlesWidget: (value, meta) {
                                        final idx = value.toInt();
                                        if (idx < 0 || idx >= display.length) {
                                          return const SizedBox.shrink();
                                        }
                                        return RotatedBox(
                                          quarterTurns: 1,
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              right: 8.0,
                                            ),
                                            child: SizedBox(
                                              width: 100,
                                              child: Text(
                                                display[idx].topicName,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 40,
                                      getTitlesWidget: (value, meta) {
                                        return RotatedBox(
                                          quarterTurns: 1,
                                          child: Text(value.toInt().toString()),
                                        );
                                      },
                                    ),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                borderData: FlBorderData(
                                  show: true,
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
                                ),
                                barGroups: barGroups,
                                gridData: const FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                ),
                              ),
                            ),
                          );
                        },
                        (failure) {
                          return Center(
                            child: Text('Error: ${failure.message}'),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Shows your relative pace across topics (lower is faster)',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
