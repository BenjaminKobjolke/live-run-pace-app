import 'package:flutter/material.dart';
import '../models/run_screen_layout.dart';
import '../models/running_session.dart';
import 'run_screen_callbacks.dart';
import 'run_screen_grid.dart';

/// Swipeable pager over the configured run screens.
///
/// Owns the [PageController] in its State so the current page survives the
/// controller-driven rebuilds (the session notifies every 10 s). Page dots
/// are shown only when there is something to swipe to.
class RunScreenPager extends StatefulWidget {
  /// The configured screens, in page order.
  final RunScreenLayouts layouts;

  /// The live session tiles read from.
  final RunningSession session;

  /// Actions and button state for control tiles.
  final RunScreenCallbacks callbacks;

  /// The 1 s time-tick source for tick-subscribed tiles.
  final Listenable? tick;

  const RunScreenPager({
    super.key,
    required this.layouts,
    required this.session,
    required this.callbacks,
    this.tick,
  });

  @override
  State<RunScreenPager> createState() => _RunScreenPagerState();
}

class _RunScreenPagerState extends State<RunScreenPager> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screens = widget.layouts.screens;

    return Column(
      children: [
        Expanded(
          // No keep-alive / implicit-scrolling cache: off-screen pages are
          // not built, so only the visible screen's tiles tick (pinned by
          // run_screen_pager_test.dart).
          child: PageView.builder(
            controller: _pageController,
            itemCount: screens.length,
            onPageChanged: (page) => setState(() => _currentPage = page),
            itemBuilder: (context, index) => RunScreenGrid(
              screen: screens[index],
              session: widget.session,
              callbacks: widget.callbacks,
              tick: widget.tick,
            ),
          ),
        ),
        if (screens.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < screens.length; i++)
                  Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _currentPage ? Colors.white : Colors.white30,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
