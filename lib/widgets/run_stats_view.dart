import 'package:flutter/material.dart';
import '../models/running_session.dart';

/// The central live-stats column of the running screen: current segment
/// distance, current/next target times, time left, and projected finish time.
class RunStatsView extends StatelessWidget {
  /// The session whose live values are displayed.
  final RunningSession session;

  const RunStatsView({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Text(
          session.currentSegmentDistanceDisplay,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _StatColumn(label: 'Current', value: session.currentTimeDisplay),
            _StatColumn(label: 'Next target', value: session.nextTargetTimeDisplay),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Time left',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          session.timeLeftDisplay,
          style: TextStyle(
            color: session.isOverTime ? Colors.red : Colors.green,
            fontSize: 42,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Finish time',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          session.finishTimeDisplay,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
      ],
    );
  }
}

/// A small label-over-value pair used for the Current / Next target readouts.
class _StatColumn extends StatelessWidget {
  final String label;
  final String value;

  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
