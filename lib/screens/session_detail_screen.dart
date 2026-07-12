import 'package:flutter/material.dart';
import '../models/running_session.dart';

class SessionDetailScreen extends StatelessWidget {
  final RunningSession session;

  const SessionDetailScreen({
    super.key,
    required this.session,
  });

  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
  }

  String _formatPace(Duration? duration) {
    if (duration == null) return '--:--';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final completedTargets = session.targets.where((t) => t.actualTime != null).toList();

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
            // Session Overview
            Card(
              color: const Color(0xFF1A1A1A),
              child: Padding(
                padding: const EdgeInsets.all(16),
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
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
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
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Time',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              Text(
                                _formatDuration(session.totalTime),
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Average Pace',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              Text(
                                session.averagePaceDisplay,
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Best Km',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              Text(
                                _formatPace(session.bestKmTime),
                                style: const TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Slowest Km',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              Text(
                                _formatPace(session.worstKmTime),
                                style: const TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Kilometer Breakdown
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
              Card(
                color: const Color(0xFF1A1A1A),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    session.isAborted
                        ? 'Session was aborted before completing any kilometers.'
                        : 'No completed kilometers in this session.',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              )
            else
              ...completedTargets.map((target) {
                final isUnderTarget = target.actualTime != null &&
                    target.actualTime!.inSeconds < session.targetPace.inSeconds;

                // Check if this is a partial last kilometer
                final isLastTarget = target.kmNumber == session.totalKilometers;
                final lastSegmentDistance = session.distance - (session.totalKilometers - 1);
                final isPartialLast = isLastTarget && lastSegmentDistance < 1.0;

                String distanceLabel;
                String circleLabel;
                if (isPartialLast) {
                  final meters = (lastSegmentDistance * 1000).round();
                  distanceLabel = '$meters meters';
                  circleLabel = '${(lastSegmentDistance * 1000).round()}m';
                  // Shorten circle label if too long
                  if (circleLabel.length > 4) {
                    circleLabel = '${target.kmNumber}';
                  }
                } else {
                  distanceLabel = 'Kilometer ${target.kmNumber}';
                  circleLabel = '${target.kmNumber}';
                }

                return Card(
                  color: const Color(0xFF1A1A1A),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isUnderTarget ? Colors.green : Colors.red,
                      child: Text(
                        circleLabel,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: circleLabel.length > 3 ? 12 : 14,
                        ),
                      ),
                    ),
                    title: Text(
                      distanceLabel,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      'Completed at ${target.completedAt != null ? _formatTime(target.completedAt!) : 'Unknown'}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatPace(target.actualTime),
                          style: TextStyle(
                            color: isUnderTarget ? Colors.green : Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'pace',
                          style: const TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),

            const SizedBox(height: 16),

            // Target Information
            Card(
              color: const Color(0xFF1A1A1A),
              child: Padding(
                padding: const EdgeInsets.all(16),
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Target Pace',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              Text(
                                _formatPace(session.targetPace),
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Max Pace',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              Text(
                                _formatPace(session.maxPace),
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}