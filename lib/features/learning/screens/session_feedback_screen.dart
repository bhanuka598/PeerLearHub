import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../skill_provider/models/provider_session.dart';
import '../../skill_provider/services/review_service.dart';
import '../../skill_provider/utils/display_utils.dart';
import '../../skill_provider/widgets/app_header.dart';

class SessionFeedbackScreen extends StatefulWidget {
  const SessionFeedbackScreen({super.key, required this.session});

  final ProviderSession session;

  @override
  State<SessionFeedbackScreen> createState() => _SessionFeedbackScreenState();
}

class _SessionFeedbackScreenState extends State<SessionFeedbackScreen> {
  final _reviewService = ReviewService.instance;
  final _commentController = TextEditingController();
  int _rating = 0;
  bool _saving = false;
  bool _submitted = false;

  ProviderSession get session => widget.session;

  @override
  void initState() {
    super.initState();
    _hydrateExisting();
  }

  Future<void> _hydrateExisting() async {
    await _reviewService.refresh();
    final existing = _reviewService.existingReviewForSession(session.id);
    if (existing != null && mounted) {
      setState(() {
        _rating = existing.rating.round().clamp(1, 5);
        if (_commentController.text.isEmpty) {
          _commentController.text = existing.comment;
        }
        _submitted = true;
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (session.status != SessionStatus.completed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feedback is available after the teacher completes this session.'),
        ),
      );
      return;
    }
    if (_rating < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a star rating first.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _reviewService.addReview(
        providerId: session.providerId,
        lessonId: session.lessonId,
        lessonTitle: session.lessonTitle,
        rating: _rating.toDouble(),
        comment: _commentController.text,
        sessionId: session.id,
      );
      if (!mounted) return;
      setState(() => _submitted = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks for your feedback.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Bad state: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = session.status == SessionStatus.completed;
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const TealPageHeader(title: 'Session Feedback'),
      body: ListView(
        padding: const EdgeInsets.all(16),
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
                Text(
                  formatDateTime(session.scheduledAt),
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 4),
                Text('Status: ${session.status.label}'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: AppTheme.cardDecoration,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your rating',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (index) {
                    final star = index + 1;
                    return IconButton(
                      onPressed: !canSubmit || _saving
                          ? null
                          : () => setState(() => _rating = star),
                      icon: Icon(
                        star <= _rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _commentController,
                  enabled: canSubmit && !_saving,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Feedback',
                    hintText: 'What went well? What could improve?',
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: !canSubmit || _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_submitted ? 'Update feedback' : 'Submit feedback'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
