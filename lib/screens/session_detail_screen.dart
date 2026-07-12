import 'package:flutter/material.dart';
import '../models/running_session.dart';
import '../widgets/km_breakdown_tile.dart';

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String _formatDate(DateTime date) =>
    '${date.day} ${_months[date.month - 1]} ${date.year}';

String _formatTime(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
  final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}

String _formatPace(Duration? duration) {
  if (duration == null) return '--:--';
  return '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
}

/// Read-only detail view of a past session: overview stats, per-kilometer
/// breakdown, and the pace targets the run was configured with.
class SessionDetailScreen extends StatelessWidget {
  final RunningSession session;

  const SessionDetailScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final completedTargets = session.targets
        .where((t) => t.actualTime != null)
        .toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Session Details'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SessionOverviewCard(session: session),
            const SizedBox(height: 16),
            const Text(
              'Kilometer Breakdown',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (completedTargets.isEmpty)
              _EmptyBreakdownCard(isAborted: session.isAborted)
            else
              ...completedTargets.map(
                (target) => KmBreakdownTile(target: target, session: session),
              ),
            const SizedBox(height: 16),
            _SessionTargetsCard(session: session),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

/// A dark card wrapper shared by the detail sections.
class _DetailCard extends StatelessWidget {
  final Widget child;

  const _DetailCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1A1A1A),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

/// A labelled statistic occupying equal horizontal space within a row.
class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final double valueSize;

  const _StatColumn({
    required this.label,
    required this.value,
    this.valueColor = Colors.white,
    this.valueSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: valueSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Overview: distance/date header plus total time, average pace, best and
/// slowest kilometer.
class _SessionOverviewCard extends StatelessWidget {
  final RunningSession session;

  const _SessionOverviewCard({required this.session});

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${session.distance.toStringAsFixed(1)} km Run',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (session.isAborted) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange, width: 1),
                  ),
                  child: const Text(
                    'ABORTED',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_formatDate(session.startTime)} at ${_formatTime(session.startTime)}',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatColumn(
                label: 'Total Time',
                value: _formatDuration(session.totalTime),
              ),
              _StatColumn(
                label: 'Average Pace',
                value: session.averagePaceDisplay,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatColumn(
                label: 'Best Km',
                value: _formatPace(session.bestKmTime),
                valueColor: Colors.green,
                valueSize: 16,
              ),
              _StatColumn(
                label: 'Slowest Km',
                value: _formatPace(session.worstKmTime),
                valueColor: Colors.red,
                valueSize: 16,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The pace targets (target and max) the session was configured with.
class _SessionTargetsCard extends StatelessWidget {
  final RunningSession session;

  const _SessionTargetsCard({required this.session});

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Session Targets',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatColumn(
                label: 'Target Pace',
                value: _formatPace(session.targetPace),
                valueSize: 14,
              ),
              _StatColumn(
                label: 'Max Pace',
                value: _formatPace(session.maxPace),
                valueSize: 14,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shown in place of the breakdown when a session has no completed kilometers.
class _EmptyBreakdownCard extends StatelessWidget {
  final bool isAborted;

  const _EmptyBreakdownCard({required this.isAborted});

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      child: Text(
        isAborted
            ? 'Session was aborted before completing any kilometers.'
            : 'No completed kilometers in this session.',
        style: const TextStyle(color: Colors.white70),
      ),
    );
  }
}
