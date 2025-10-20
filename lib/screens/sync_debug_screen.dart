import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/connectivity_service.dart';
import '../services/sync_service.dart';
import '../widgets/sync_status_widget.dart';
import '../widgets/connectivity_indicator.dart';
import '../utils/constants.dart';

class SyncDebugScreen extends StatelessWidget {
  const SyncDebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Status & Debug'),
        actions: const [ConnectivityIndicator()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Consumer<ConnectivityService>(
                  builder: (context, conn, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Connectivity',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text('Status: ${conn.currentState.status.name}'),
                        Text('Type: ${conn.currentState.type.name}'),
                        Text('Last checked: ${conn.currentState.lastChecked}'),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Consumer2<ConnectivityService, SyncService>(
                  builder: (context, conn, sync, _) {
                    final status = sync.syncStatus;
                    final q = conn.queueState;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sync Status',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text('User: ${status.userId}'),
                        Text('Last synced: ${status.lastSyncedAt ?? 'Never'}'),
                        Text('Pending: ${q.pendingCount}'),
                        Text('Failed: ${q.failedCount}'),
                        Text('Processing: ${q.processingCount}'),
                        Text('Completed: ${q.completedCount}'),
                        Text('Is syncing: ${status.isSyncing}'),
                        if (status.lastError != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Last error: ${status.lastError}',
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sync Queue',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const SyncStatusWidget(compact: false),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Consumer2<ConnectivityService, SyncService>(
                  builder: (context, conn, sync, _) {
                    return Row(
                      children: [
                        ElevatedButton(
                          onPressed: (!conn.isOnline || sync.isSyncing)
                              ? null
                              : () async {
                                  final res = await sync.forceSyncNow(
                                    'demo_user',
                                  );
                                  res.fold(
                                    (_) => ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                          const SnackBar(
                                            content: Text('Sync started'),
                                          ),
                                        ),
                                    (failure) => ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Sync failed: ${failure.message}',
                                            ),
                                          ),
                                        ),
                                  );
                                },
                          child: const Text('Sync All Data'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Clear sync queue?'),
                                content: const Text(
                                  'This will remove all pending sync operations.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Confirm'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              await conn.clearQueue();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Queue cleared')),
                              );
                            }
                          },
                          child: const Text('Clear Sync Queue'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: conn.isOnline
                              ? () => conn.retryFailedOperations()
                              : null,
                          child: const Text('Retry Failed'),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Debug Info', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text('Base URL: ${SyncConstants.baseUrl}'),
            const Text('API Version: ${SyncConstants.apiVersion}'),
            const Text('Auto-sync enabled: ${SyncConstants.enableAutoSync}'),
            const Text(
              'Conflict strategy: ${SyncConstants.conflictResolutionStrategy}',
            ),
          ],
        ),
      ),
    );
  }
}
