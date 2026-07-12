class DistanceEntry {
  final double distance;
  final DateTime firstUsed;
  final DateTime lastUsed;
  final int usageCount;

  const DistanceEntry({
    required this.distance,
    required this.firstUsed,
    required this.lastUsed,
    required this.usageCount,
  });

  Map<String, dynamic> toJson() => {
    'distance': distance,
    'firstUsed': firstUsed.toIso8601String(),
    'lastUsed': lastUsed.toIso8601String(),
    'usageCount': usageCount,
  };

  factory DistanceEntry.fromJson(Map<String, dynamic> json) => DistanceEntry(
    distance: (json['distance'] as num).toDouble(),
    firstUsed: DateTime.parse(json['firstUsed'] as String),
    lastUsed: DateTime.parse(json['lastUsed'] as String),
    usageCount: json['usageCount'] as int,
  );

  DistanceEntry copyWith({
    double? distance,
    DateTime? firstUsed,
    DateTime? lastUsed,
    int? usageCount,
  }) => DistanceEntry(
    distance: distance ?? this.distance,
    firstUsed: firstUsed ?? this.firstUsed,
    lastUsed: lastUsed ?? this.lastUsed,
    usageCount: usageCount ?? this.usageCount,
  );
}

class DistanceHistory {
  final List<DistanceEntry> entries;

  const DistanceHistory({this.entries = const []});

  Map<String, dynamic> toJson() => {
    'entries': entries.map((e) => e.toJson()).toList(),
  };

  factory DistanceHistory.fromJson(Map<String, dynamic> json) =>
      DistanceHistory(
        entries: (json['entries'] as List? ?? [])
            .map((e) => DistanceEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  DistanceHistory addDistance(double distance) {
    final now = DateTime.now();
    final roundedDistance = _roundDistance(distance);

    final existingIndex = entries.indexWhere(
      (entry) => (entry.distance - roundedDistance).abs() < 0.05,
    );

    if (existingIndex != -1) {
      final updatedEntries = List<DistanceEntry>.from(entries);
      updatedEntries[existingIndex] = entries[existingIndex].copyWith(
        lastUsed: now,
        usageCount: entries[existingIndex].usageCount + 1,
      );
      return DistanceHistory(entries: updatedEntries);
    } else {
      final newEntry = DistanceEntry(
        distance: roundedDistance,
        firstUsed: now,
        lastUsed: now,
        usageCount: 1,
      );
      return DistanceHistory(entries: [...entries, newEntry]);
    }
  }

  List<double> getSuggestions({int limit = 8}) {
    final now = DateTime.now();
    final sixMonthsAgo = now.subtract(const Duration(days: 180));

    // Filter out old entries and sort by usage frequency and recency
    final recentEntries = entries
        .where((entry) => entry.lastUsed.isAfter(sixMonthsAgo))
        .toList();

    recentEntries.sort((a, b) {
      // Primary sort: usage count (descending)
      final usageComparison = b.usageCount.compareTo(a.usageCount);
      if (usageComparison != 0) return usageComparison;

      // Secondary sort: recency (descending)
      return b.lastUsed.compareTo(a.lastUsed);
    });

    return recentEntries.take(limit).map((entry) => entry.distance).toList();
  }

  DistanceHistory cleanup() {
    final now = DateTime.now();
    final sixMonthsAgo = now.subtract(const Duration(days: 180));

    // Keep only recent entries, max 20 total
    final recentEntries = entries
        .where((entry) => entry.lastUsed.isAfter(sixMonthsAgo))
        .toList();

    recentEntries.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));

    return DistanceHistory(entries: recentEntries.take(20).toList());
  }

  double _roundDistance(double distance) {
    // Round to 0.1 km precision to avoid over-fragmentation
    return (distance * 10).round() / 10;
  }
}
