import 'package:flutter/material.dart';
import '../services/ab_test_service.dart';
import '../models/cloud_ai_models.dart';

class CloudAIIndicator extends StatefulWidget {
  final bool compact;
  const CloudAIIndicator({this.compact = false, super.key});

  @override
  State<CloudAIIndicator> createState() => _CloudAIIndicatorState();
}

class _CloudAIIndicatorState extends State<CloudAIIndicator> {
  String _group = 'unknown';
  bool _available = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    try {
      final group = ABTestService.instance.getCurrentGroup();
      setState(() {
        _group = group.toJson();
        _available = true;
      });
    } catch (_) {
      setState(() {
        _group = 'n/a';
        _available = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _available ? Colors.green : Colors.grey;
    final text = _available ? 'AI: $_group' : 'AI: off';
    if (widget.compact) {
      return InkWell(
        onTap: _refresh,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withOpacity(0.6)),
          ),
          child: Text(text, style: TextStyle(fontSize: 12, color: color)),
        ),
      );
    }

    return Row(
      children: [
        Icon(Icons.smart_toy, size: 18, color: color),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: color)),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.refresh, size: 18),
          onPressed: _refresh,
          tooltip: 'Refresh Cloud AI status',
        ),
      ],
    );
  }
}
