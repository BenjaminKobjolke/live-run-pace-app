import 'package:flutter/material.dart';
import '../models/running_session.dart';
import '../services/storage_service.dart';
import 'session_detail_screen.dart';

/// Lists past sessions (newest first); tap opens details, long-press deletes.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<RunningSession> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    try {
      final sessions = await StorageService.instance.loadSessionHistory();
      setState(() {
        _sessions = sessions.reversed.toList(); // newest first
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteSession(RunningSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF333333),
        title: const Text(
          'Delete Session?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete this ${session.distance.toStringAsFixed(1)} km session?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await StorageService.instance.deleteSession(session.id);
      _loadSessions(); // Refresh the list
    }
  }

  void _openDetail(RunningSession session) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SessionDetailScreen(session: session),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Session History'),
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    if (_sessions.isEmpty) {
      return const Center(
        child: Text(
          'No sessions yet.\nComplete a run to see history here.',
          style: TextStyle(color: Colors.white70, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView.builder(
      itemCount: _sessions.length,
      itemBuilder: (context, index) {
        final session = _sessions[index];
        return _SessionHistoryTile(
          session: session,
          onTap: () => _openDetail(session),
          onDelete: () => _deleteSession(session),
        );
      },
    );
  }
}

/// A single session card in the history list, with distance, an optional
/// ABORTED badge, and start time / duration / average-pace stats.
class _SessionHistoryTile extends StatelessWidget {
  final RunningSession session;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SessionHistoryTile({
    required this.session,
    required this.onTap,
    required this.onDelete,
  });

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        color: const Color(0xFF1A1A1A),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          onTap: onTap,
          onLongPress: onDelete,
          title: _buildTitle(),
          subtitle: _buildSubtitle(),
          trailing: const Icon(Icons.chevron_right, color: Colors.white30),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Row(
      children: [
        Text(
          '${session.distance.toStringAsFixed(1)} km',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (session.isAborted) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange, width: 1),
            ),
            child: const Text(
              'ABORTED',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        const Spacer(),
        Text(
          _formatDate(session.startTime),
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildSubtitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            _stat(Icons.access_time, _formatTime(session.startTime)),
            const SizedBox(width: 16),
            _stat(Icons.timer, _formatDuration(session.totalTime)),
            const SizedBox(width: 16),
            _stat(Icons.speed, session.averagePaceDisplay),
          ],
        ),
      ],
    );
  }

  Widget _stat(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
