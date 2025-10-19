import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import '../services/connectivity_service.dart';
import '../models/connectivity_models.dart';

class ConnectivityIndicator extends StatelessWidget {
  final bool showLabel;
  final Color? onlineColor;
  final Color? offlineColor;

  const ConnectivityIndicator({
    this.showLabel = false,
    this.onlineColor,
    this.offlineColor,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivity, child) {
        final state = connectivity.currentState;
        IconData icon;
        Color color;
        String label;
        switch (state.status) {
          case ConnectivityStatus.online:
            icon = Icons.cloud_done;
            color = onlineColor ?? Colors.green;
            label = 'Online';
            break;
          case ConnectivityStatus.offline:
            icon = Icons.cloud_off;
            color = offlineColor ?? Colors.red;
            label = 'Offline';
            break;
          case ConnectivityStatus.checking:
            icon = Icons.cloud_queue;
            color = Colors.grey;
            label = 'Checking...';
            break;
        }
        return Tooltip(
          message:
              '$label via ${describeEnum(state.type)}\nLast checked: ${state.lastChecked}',
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              if (showLabel) ...[
                const SizedBox(width: 4),
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: color),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
