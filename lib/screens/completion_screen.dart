import 'package:flutter/material.dart';
import '../models/running_session.dart';
import 'home_screen.dart';

/// Post-run summary: total distance/time, a per-kilometer breakdown, and a way
/// back home.
class CompletionScreen extends StatelessWidget {
  final RunningSession session;

  const CompletionScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final completedTargets = session.targets
        .where((target) => target.completedAt != null)
        .toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 32),
              _CompletionHeader(session: session),
              const SizedBox(height: 32),
              const Text(
                'Kilometer Breakdown',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: completedTargets.length,
                  itemBuilder: (context, index) => _KilometerBreakdownTile(
                    session: session,
                    target: completedTargets[index],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const _HomeButton(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

/// Title plus total distance and total time for the finished [session].
class _CompletionHeader extends StatelessWidget {
  final RunningSession session;

  const _CompletionHeader({required this.session});

  @override
  Widget build(BuildContext context) {
    final elapsed = session.elapsedTime;
    final timeText =
        '${elapsed.inHours}:'
        '${(elapsed.inMinutes % 60).toString().padLeft(2, '0')}:'
        '${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}';
    return Column(
      children: [
        const Text(
          'Session Completed!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Total Distance: ${session.distance.toStringAsFixed(2)} km',
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        Text(
          'Total Time: $timeText',
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ],
    );
  }
}

/// One row of the kilometer breakdown, labelling partial final segments in
/// meters and full segments as "Km N".
class _KilometerBreakdownTile extends StatelessWidget {
  final RunningSession session;
  final KilometerTarget target;

  const _KilometerBreakdownTile({required this.session, required this.target});

  @override
  Widget build(BuildContext context) {
    final isLastTarget = target.kmNumber == session.totalKilometers;
    final lastSegmentDistance =
        session.distance - (session.totalKilometers - 1);
    final isPartialLast = isLastTarget && lastSegmentDistance < 1.0;
    final distanceLabel = isPartialLast
        ? '${(lastSegmentDistance * 1000).round()} m'
        : 'Km ${target.kmNumber}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            distanceLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                target.timeDisplay,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              Text(
                'Pace: ${target.actualPaceDisplay}/km',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Full-width button that returns to the home screen, clearing the run stack.
class _HomeButton extends StatelessWidget {
  const _HomeButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        child: const Text(
          'HOME',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
