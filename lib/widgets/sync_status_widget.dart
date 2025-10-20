import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';
// import '../models/sync_models.dart';
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
    return Consumer2<ConnectivityService, SyncService>(
      builder: (context, connectivity, syncService, child) {
        final queue = connectivity.queueState;
        final syncStatus = syncService.syncStatus;
        if (!queue.hasOperations() &&
            syncStatus.lastSyncedAt == null &&
            !compact)
          return SizedBox.shrink();
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
                if (syncService.isSyncing || queue.isProcessing) ...[
                  Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text('Syncing ${queue.processingCount} items...'),
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
                if (syncStatus.lastSyncedAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Last synced: ${formatTimestamp(syncStatus.lastSyncedAt)}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ] else if (queue.lastProcessedAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Last processed: ${formatTimestamp(queue.lastProcessedAt)}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ],

                if (syncStatus.lastError != null && !compact) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, size: 16, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            syncStatus.lastError!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.red.shade900),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (queue.failedCount > 0 && !compact) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        onPressed: () => connectivity.retryFailedOperations(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry Failed'),
                      ),
                      if (connectivity.isOnline)
                        TextButton.icon(
                          onPressed: () =>
                              syncService.forceSyncNow('demo_user'),
                          icon: const Icon(Icons.sync),
                          label: const Text('Sync Now'),
                        ),
                    ],
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
