import 'dart:math';

/// Session-scoped shuffle bag over a fixed list of audio file paths.
///
/// [next] returns each path exactly once per cycle in random order, refilling
/// (and reshuffling) when the bag runs dry. Across a refill the same path is
/// never returned twice in a row, unless only one path is configured.
class Mp3ShuffleBag {
  final List<String> _paths;
  final Random _random;
  final List<String> _bag = [];
  String? _last;

  /// Creates a bag over a copy of [paths]. Pass [random] to make picks
  /// deterministic in tests.
  Mp3ShuffleBag(List<String> paths, {Random? random})
    : _paths = List.of(paths),
      _random = random ?? Random();

  /// True when no paths were configured — [next] would throw.
  bool get isEmpty => _paths.isEmpty;

  /// Returns the next path to play. Throws [StateError] when the bag was
  /// constructed with an empty list.
  String next() {
    if (_paths.isEmpty) {
      throw StateError('Mp3ShuffleBag has no paths configured');
    }
    if (_bag.isEmpty) _refill();
    final pick = _bag.removeLast();
    _last = pick;
    return pick;
  }

  void _refill() {
    _bag.addAll(_paths);
    _bag.shuffle(_random);
    // A fresh shuffle may lead with the path that just played; swap it away
    // so no path repeats back-to-back across the refill boundary.
    if (_bag.length > 1 && _bag.last == _last) {
      final other = _random.nextInt(_bag.length - 1);
      _bag[_bag.length - 1] = _bag[other];
      _bag[other] = _last!;
    }
  }
}
