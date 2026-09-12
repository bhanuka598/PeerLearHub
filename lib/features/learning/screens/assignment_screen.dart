import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/role_switcher_button.dart';
import '../models/learning_course.dart';
import '../services/assignment_service.dart';

class AssignmentScreen extends StatefulWidget {
  const AssignmentScreen({super.key, required this.course});

  final LearningCourse course;

  @override
  State<AssignmentScreen> createState() => _AssignmentScreenState();
}

class _AssignmentScreenState extends State<AssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _githubUrl = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _description.dispose();
    _githubUrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _submitting = true);
    try {
      await AssignmentService.instance.submit(
        courseId: widget.course.id,
        description: _description.text,
        githubUrl: _githubUrl.text,
      );
      if (mounted) {
        setState(() => _submitted = true);
      }
    } catch (error) {
      if (mounted) {
        _showError(error.toString().replaceFirst('ArgumentError: ', '').replaceFirst('StateError: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<Uint8List> _certificateBytes() async {
    final document = pw.Document();
    document.addPage(
      pw.Page(
        build: (context) => pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                'CERTIFICATE OF COMPLETION',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 24),
              pw.Text('This certifies that the learner completed'),
              pw.SizedBox(height: 8),
              pw.Text(
                widget.course.title,
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 24),
              pw.Text('PeerLearnHub'),
            ],
          ),
        ),
      ),
    );
    return document.save();
  }

  Future<void> _shareCertificate() async {
    await SharePlus.instance.share(
      ShareParams(text: 'I completed ${widget.course.title} on PeerLearnHub.'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Final Assignment'),
        actions: const [RoleSwitcherButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.course.title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Submit your GitHub repository URL and description to receive your certificate of completion.',
          ),
          const SizedBox(height: 20),
          if (_submitted)
            _CertificatePanel(
              course: widget.course,
              onShare: _shareCertificate,
              onDownload: () async => Printing.sharePdf(
                bytes: await _certificateBytes(),
                filename: 'peerlearnhub-${widget.course.id}-certificate.pdf',
              ),
            )
          else
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _description,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Assignment description',
                      alignLabelWithHint: true,
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Describe your submission.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _githubUrl,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'GitHub repository URL',
                      prefixIcon: Icon(Icons.link),
                    ),
                    validator: (value) =>
                        value == null || !value.contains('github.com/')
                        ? 'Enter a valid GitHub repository URL.'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const CircularProgressIndicator()
                          : const Text('Submit Assignment'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CertificatePanel extends StatelessWidget {
  const _CertificatePanel({
    required this.course,
    required this.onShare,
    required this.onDownload,
  });

  final LearningCourse course;
  final VoidCallback onShare;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) => Card(
    color: AppTheme.primaryColor.withValues(alpha: .08),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(
            Icons.workspace_premium,
            size: 56,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 12),
          const Text(
            'Certificate of Completion',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('You completed ${course.title}.'),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onDownload,
                icon: const Icon(Icons.download),
                label: const Text('Download'),
              ),
              FilledButton.icon(
                onPressed: onShare,
                icon: const Icon(Icons.share),
                label: const Text('Share'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
