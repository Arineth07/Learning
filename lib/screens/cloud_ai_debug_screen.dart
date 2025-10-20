import 'package:flutter/material.dart';
import '../services/cloud_ai_cache_service.dart';
import '../services/ab_test_service.dart';
import '../models/cloud_ai_models.dart';

class CloudAIDebugScreen extends StatefulWidget {
  const CloudAIDebugScreen({super.key});

  @override
  State<CloudAIDebugScreen> createState() => _CloudAIDebugScreenState();
}

class _CloudAIDebugScreenState extends State<CloudAIDebugScreen> {
  Map<String, dynamic> _cacheStats = {};
  ABTestMetrics? _metrics;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final stats = CloudAICacheService.instance.getCacheStats();
    final metrics = ABTestService.instance.getCurrentMetrics();
    setState(() {
      _cacheStats = stats;
      _metrics = metrics;
    });
  }

  Future<void> _clearCache() async {
    await CloudAICacheService.instance.invalidateAll();
    await _refresh();
  }

  Future<void> _reassignAB(ABTestGroup group) async {
    await ABTestService.instance.setGroup(group);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cloud AI Debug')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView(
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.storage),
                title: const Text('Cloud AI Cache'),
                subtitle: Text('Entries: ${_cacheStats['totalEntries'] ?? 0}'),
                trailing: ElevatedButton(
                  onPressed: _clearCache,
                  child: const Text('Clear'),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.assessment),
                title: const Text('Cache Stats'),
                subtitle: Text(
                  'Hits: ${_cacheStats['totalHits'] ?? 0}  Misses: ${_cacheStats['totalMisses'] ?? 0}\nHitRate: ${(_cacheStats['hitRate'] ?? 0.0).toStringAsFixed(2)}',
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.group),
                title: const Text('A/B Test Metrics'),
                subtitle: Text(
                  _metrics != null
                      ? _metrics!.toJson().toString()
                      : 'No metrics yet',
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Actions',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _refresh,
                      child: const Text('Refresh'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _reassignAB(ABTestGroup.ruleBased),
                      child: const Text('Force Rule-based Group'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _reassignAB(ABTestGroup.cloudAI),
                      child: const Text('Force Cloud-AI Group'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _reassignAB(ABTestGroup.hybrid),
                      child: const Text('Force Hybrid Group'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
