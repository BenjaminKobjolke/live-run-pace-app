import 'package:flutter/material.dart';
import '../models/running_session.dart';

/// A single completed-kilometer row in the session detail breakdown.
class KmBreakdownTile extends StatelessWidget {
  /// The completed kilometer target to display.
  final KilometerTarget target;

  /// The owning session (for distance/pace context).
  final RunningSession session;

  const KmBreakdownTile({
    super.key,
    required this.target,
    required this.session,
  });

  static String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String _formatPace(Duration? duration) {
    if (duration == null) return '--:--';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isUnderTarget =
        target.actualTime != null &&
        target.actualTime!.inSeconds < session.targetPace.inSeconds;

    // Check if this is a partial last kilometer
    final isLastTarget = target.kmNumber == session.totalKilometers;
    final lastSegmentDistance =
        session.distance - (session.totalKilometers - 1);
    final isPartialLast = isLastTarget && lastSegmentDistance < 1.0;

    String distanceLabel;
    String circleLabel;
    if (isPartialLast) {
      final meters = (lastSegmentDistance * 1000).round();
      distanceLabel = '$meters meters';
      circleLabel = '${meters}m';
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
        title: Text(distanceLabel, style: const TextStyle(color: Colors.white)),
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
            const Text(
              'pace',
              style: TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
