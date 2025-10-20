import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/adaptive_learning_service.dart';
import '../../models/models.dart';
import '../../utils/result.dart';

class PerformanceTrendChart extends StatefulWidget {
  final String userId;
  final String subjectId;
  final bool showRefresh;

  const PerformanceTrendChart({
    super.key,
    required this.userId,
    required this.subjectId,
    this.showRefresh = true,
  });

  @override
  State<PerformanceTrendChart> createState() => _PerformanceTrendChartState();
}

class _PerformanceTrendChartState extends State<PerformanceTrendChart> {
  late Future<Result<PerformanceTrend>> _trendFuture;

  @override
  void initState() {
    super.initState();
    _trendFuture = _loadTrend();
  }

  Future<Result<PerformanceTrend>> _loadTrend() {
    final service = context.read<AdaptiveLearningService>();
    return service.analyzePerformanceTrend(widget.userId, widget.subjectId);
  }

  Future<void> _refresh() async {
    setState(() {
      _trendFuture = _loadTrend();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and refresh button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Performance Trend',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _refresh,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Fixed-height container so the chart can be embedded safely in scrollable parents
            SizedBox(
              height: 200,
              child: FutureBuilder<Result<PerformanceTrend>>(
                future: _trendFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError || !snapshot.hasData) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Failed to load performance data'),
                          if (snapshot.error != null)
                            Text(
                              '${snapshot.error}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.red),
                            ),
                        ],
                      ),
                    );
                  }

                  return snapshot.data!.fold(
                    (trend) {
                      if (trend.accuracyHistory.isEmpty) {
                        return const Center(
                          child: Text('No performance data available yet'),
                        );
                      }

                      final points = <FlSpot>[];
                      for (var i = 0; i < trend.accuracyHistory.length; i++) {
                        points.add(
                          FlSpot(i.toDouble(), trend.accuracyHistory[i]),
                        );
                      }

                      String trendLabel;
                      Color trendColor;
                      switch (trend.trendDirection.toLowerCase()) {
                        case 'improving':
                          trendLabel = 'Improving 📈';
                          trendColor = Colors.green;
                          break;
                        case 'declining':
                          trendLabel = 'Declining 📉';
                          trendColor = Colors.red;
                          break;
                        default:
                          trendLabel = 'Stable 📊';
                          trendColor = Colors.blue;
                      }

                      return Column(
                        children: [
                          // Chart
                          Expanded(
                            child: LineChart(
                              LineChartData(
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: points,
                                    isCurved: true,
                                    color: trendColor,
                                    barWidth: 3,
                                    dotData: const FlDotData(show: true),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: trendColor.withOpacity(0.1),
                                    ),
                                  ),
                                ],
                                gridData: const FlGridData(show: true),
                                borderData: FlBorderData(
                                  border: const Border(
                                    bottom: BorderSide(),
                                    left: BorderSide(),
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  bottomTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval: 0.2,
                                      reservedSize: 40,
                                      getTitlesWidget: (value, _) {
                                        return Text(
                                          '${(value * 100).toInt()}%',
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                minY: 0,
                                maxY: 1,
                                lineTouchData: LineTouchData(
                                  touchTooltipData: LineTouchTooltipData(
                                    getTooltipItems: (spots) {
                                      return spots.map((spot) {
                                        return LineTooltipItem(
                                          '${(spot.y * 100).toStringAsFixed(1)}%',
                                          const TextStyle(color: Colors.white),
                                        );
                                      }).toList();
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                trendLabel,
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      color: trendColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              Text(
                                'Recent: ${(trend.recentAccuracy * 100).toStringAsFixed(1)}%',
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            trend.insight,
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      );
                    },
                    (failure) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Error loading performance data'),
                          Text(
                            failure.message,
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
