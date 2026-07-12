import 'package:flutter/material.dart';
import '../models/running_session.dart';
import 'home_screen.dart';

class CompletionScreen extends StatelessWidget {
  final RunningSession session;

  const CompletionScreen({
    super.key,
    required this.session,
  });

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
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),

              Text(
                'Total Time: ${session.elapsedTime.inHours}:${(session.elapsedTime.inMinutes % 60).toString().padLeft(2, '0')}:${(session.elapsedTime.inSeconds % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),

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
                  itemBuilder: (context, index) {
                    final target = completedTargets[index];

                    // Check if this is a partial last kilometer
                    final isLastTarget = target.kmNumber == session.totalKilometers;
                    final lastSegmentDistance = session.distance - (session.totalKilometers - 1);
                    final isPartialLast = isLastTarget && lastSegmentDistance < 1.0;

                    String distanceLabel;
                    if (isPartialLast) {
                      final meters = (lastSegmentDistance * 1000).round();
                      distanceLabel = '$meters m';
                    } else {
                      distanceLabel = 'Km ${target.kmNumber}';
                    }

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
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Pace: ${target.actualPaceDisplay}/km',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
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
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}