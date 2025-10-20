import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/connectivity_service.dart';
import '../utils/constants.dart';

class ConnectivityBanner extends StatefulWidget {
  const ConnectivityBanner({super.key});

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  bool _isDismissed = false;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    if (ConnectivityConstants.bannerAutoDismissSeconds > 0) {
      _autoDismissTimer = Timer(
        const Duration(seconds: ConnectivityConstants.bannerAutoDismissSeconds),
        () {
          if (mounted) setState(() => _isDismissed = true);
        },
      );
    }
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivity, child) {
        if (_isDismissed ||
            connectivity.isOnline ||
            !ConnectivityConstants.showBannerOnOffline) {
          return const SizedBox.shrink();
        }
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          color: Colors.orange.shade100,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.cloud_off, color: Colors.orange.shade900),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "You're offline. Some features may be limited.",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.orange.shade900,
                  ),
                ),
              ),
              if (ConnectivityConstants.bannerDismissible)
                IconButton(
                  icon: const Icon(Icons.close),
                  color: Colors.orange.shade900,
                  tooltip: 'Dismiss',
                  onPressed: () => setState(() => _isDismissed = true),
                ),
            ],
          ),
        );
      },
    );
  }
}
