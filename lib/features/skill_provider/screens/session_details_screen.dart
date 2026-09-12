import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/app_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../models/provider_session.dart';
import '../services/session_service.dart';
import '../utils/display_utils.dart';
import '../utils/session_time_utils.dart';
import '../widgets/app_header.dart';

class SessionDetailsScreen extends StatefulWidget {
  const SessionDetailsScreen({super.key, required this.session});

  final ProviderSession session;

  @override
  State<SessionDetailsScreen> createState() => _SessionDetailsScreenState();
}

class _SessionDetailsScreenState extends State<SessionDetailsScreen> {
  late ProviderSession _session;
  bool _busy = false;

  bool get _isTeacher => AppAuth.instance.currentRole == AppUserRole.teacher;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    SessionService.instance.addListener(_refresh);
    _refresh();
  }

  @override
  void dispose() {
    SessionService.instance.removeListener(_refresh);
    super.dispose();
  }

  Future<void> _refresh() async {
    final fresh = await SessionService.instance.getSessionById(_session.id);
    if (fresh != null && mounted) {
      setState(() => _session = fresh);
    }
  }

  Future<void> _markCompleted() async {
    setState(() => _busy = true);
    await SessionService.instance.markCompleted(_session.id);
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Session marked completed.')),
    );
    context.pop();
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel session'),
        content: const Text(
          'Cancelled sessions will not receive reminders or feedback requests.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel session'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    await SessionService.instance.cancelSession(_session.id);
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Session cancelled.')),
    );
    context.pop();
  }

  Future<void> _reschedule() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _session.scheduledAt.isAfter(DateTime.now())
          ? _session.scheduledAt
          : DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_session.scheduledAt),
    );
    if (time == null || !mounted) return;

    final next = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() => _busy = true);
    await SessionService.instance.rescheduleSession(_session.id, next);
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Session rescheduled to ${formatDateTime(next)}.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    final ended = hasSessionEnded(session);
    final canComplete = _isTeacher &&
        session.status == SessionStatus.upcoming &&
        ended;
    final canManage = _isTeacher && session.status == SessionStatus.upcoming;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const TealPageHeader(title: 'Session Details'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: AppTheme.cardDecoration,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.lessonTitle,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _row('Learner', session.learnerName),
                  _row('Scheduled', formatDateTime(session.scheduledAt)),
                  _row('Duration', session.duration),
                  _row('Status', session.status.label),
                  if (session.location != null)
                    _row('Location', session.location!),
                  if (session.joinLink != null)
                    _row('Join Link', session.joinLink!),
                ],
              ),
            ),
            if (canComplete) ...[
              const SizedBox(height: 16),
              Container(
                decoration: AppTheme.cardDecoration,
                padding: const EdgeInsets.all(16),
                child: const Text(
                  'This session has ended. Please mark it as completed so the learner can leave feedback.',
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (session.joinLink != null)
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Join: ${session.joinLink}')),
                  );
                },
                icon: const Icon(Icons.video_call),
                label: const Text('Join Session'),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => context.push('/skill-provider/messages'),
              icon: const Icon(Icons.message),
              label: const Text('Message Learner'),
            ),
            if (canComplete) ...[
              const SizedBox(height: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.statusActiveText,
                ),
                onPressed: _busy ? null : _markCompleted,
                child: const Text('Complete Session'),
              ),
            ],
            if (canManage) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _busy ? null : _reschedule,
                icon: const Icon(Icons.event_repeat),
                label: const Text('Reschedule Session'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _busy ? null : _cancel,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancel Session'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
