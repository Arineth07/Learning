import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/connectivity_service.dart';
// import '../models/connectivity_models.dart';

class SyncStatusWidget extends StatelessWidget {
  final bool compact;
  const SyncStatusWidget({this.compact = false, Key? key}) : super(key: key);

  String formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivity, child) {
        final queue = connectivity.queueState;
        if (!queue.hasOperations() && !compact) return SizedBox.shrink();
        return Card(
          margin: const EdgeInsets.all(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.sync, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Sync Status',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (queue.isProcessing) ...[
                  Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text('Syncing...'),
                    ],
                  ),
                ] else if (queue.pendingCount > 0) ...[
                  Row(
                    children: [
                      Icon(Icons.pending_actions, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text('${queue.pendingCount} pending'),
                    ],
                  ),
                ] else if (queue.failedCount > 0) ...[
                  Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Text('${queue.failedCount} failed'),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Text('All synced'),
                    ],
                  ),
                ],
                if (queue.lastProcessedAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Last synced: ${formatTimestamp(queue.lastProcessedAt)}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ],
                if (queue.failedCount > 0 && !compact) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => connectivity.retryFailedOperations(),
                    child: const Text('Retry Failed'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
