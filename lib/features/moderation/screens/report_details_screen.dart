import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../models/moderation_report.dart';
import '../services/moderation_service.dart';

class ReportDetailsScreen extends StatefulWidget {
  final String reportId;

  const ReportDetailsScreen({
    super.key,
    required this.reportId,
  });

  @override
  State<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
  final ModerationService _moderationService = ModerationService();
  ModerationReport? _report;
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    
    try {
      final report = await _moderationService.getReportById(widget.reportId);
      setState(() {
        _report = report;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading report: $e')),
        );
      }
    }
  }

  Future<void> _updateStatus(ReportStatus newStatus) async {
    String? resolutionNote;
    
    // For resolved/dismissed, optionally ask for note
    if (newStatus == ReportStatus.resolved || newStatus == ReportStatus.dismissed) {
      resolutionNote = await showDialog<String>(
        context: context,
        builder: (context) => _ResolutionNoteDialog(
          status: newStatus,
        ),
      );
      
      // If dialog was cancelled, don't proceed
      if (resolutionNote == null) return;
    }

    setState(() => _isProcessing = true);

    try {
      // Mock moderator ID - will be replaced with actual auth user
      await _moderationService.updateReportStatus(
        widget.reportId,
        newStatus,
        'mod_001',
        resolutionNote: resolutionNote,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report status updated to ${newStatus.displayName}'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    }
  }

  Color _getStatusColor() {
    switch (_report!.status) {
      case ReportStatus.open:
        return AppColors.error;
      case ReportStatus.underReview:
        return AppColors.pending;
      case ReportStatus.resolved:
        return AppColors.success;
      case ReportStatus.dismissed:
        return AppColors.textSecondary;
    }
  }

  Color _getSeverityColor() {
    switch (_report!.severity) {
      case ReportSeverity.low:
        return AppColors.severityLow;
      case ReportSeverity.medium:
        return AppColors.severityMedium;
      case ReportSeverity.high:
        return AppColors.severityHigh;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMMM dd, yyyy - hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _report == null
              ? const Center(child: Text('Report not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status and Severity Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Status',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor().withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: _getStatusColor(),
                                            ),
                                          ),
                                          child: Text(
                                            _report!.status.displayName,
                                            style: TextStyle(
                                              color: _getStatusColor(),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Severity',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getSeverityColor().withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: _getSeverityColor(),
                                            ),
                                          ),
                                          child: Text(
                                            _report!.severity.displayName,
                                            style: TextStyle(
                                              color: _getSeverityColor(),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Report Information
                      Text(
                        'Report Information',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailRow(
                                'Report ID',
                                _report!.id,
                                Icons.tag,
                              ),
                              const Divider(height: 24),
                              _buildDetailRow(
                                'Reason',
                                _report!.reason.displayName,
                                Icons.report_outlined,
                              ),
                              const Divider(height: 24),
                              _buildDetailRow(
                                'Reported',
                                dateFormat.format(_report!.createdAt),
                                Icons.calendar_today,
                              ),
                              if (_report!.reviewedAt != null) ...[
                                const Divider(height: 24),
                                _buildDetailRow(
                                  'Reviewed',
                                  dateFormat.format(_report!.reviewedAt!),
                                  Icons.check_circle_outline,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Users Involved
                      Text(
                        'Users Involved',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailRow(
                                'Reported User',
                                _report!.reportedUserName ?? 'Unknown',
                                Icons.person_outlined,
                              ),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.only(left: 32),
                                child: Text(
                                  'ID: ${_report!.reportedUserId}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                              const Divider(height: 24),
                              _buildDetailRow(
                                'Reported By',
                                _report!.reporterName ?? 'Anonymous',
                                Icons.person,
                              ),
                              if (_report!.relatedContentId != null) ...[
                                const Divider(height: 24),
                                _buildDetailRow(
                                  'Related Content',
                                  _report!.relatedContentId!,
                                  Icons.content_copy,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Description
                      Text(
                        'Description',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            _report!.description,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),

                      // Resolution Note (if exists)
                      if (_report!.resolutionNote != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Resolution Note',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          color: AppColors.success.withOpacity(0.05),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.note_outlined,
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _report!.resolutionNote!,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Action Buttons
                      if (_report!.status != ReportStatus.resolved &&
                          _report!.status != ReportStatus.dismissed &&
                          !_isProcessing) ...[
                        Text(
                          'Moderation Actions',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        
                        if (_report!.status == ReportStatus.open)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _updateStatus(ReportStatus.underReview),
                              icon: const Icon(Icons.pending_actions),
                              label: const Text('Mark as Under Review'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.pending,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        
                        const SizedBox(height: 12),
                        
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _updateStatus(ReportStatus.dismissed),
                                icon: const Icon(Icons.block),
                                label: const Text('Dismiss'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.textSecondary,
                                  side: const BorderSide(
                                    color: AppColors.textSecondary,
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _updateStatus(ReportStatus.resolved),
                                icon: const Icon(Icons.check_circle),
                                label: const Text('Resolve'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      if (_isProcessing)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.primaryTeal,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Resolution Note Dialog
class _ResolutionNoteDialog extends StatefulWidget {
  final ReportStatus status;

  const _ResolutionNoteDialog({
    required this.status,
  });

  @override
  State<_ResolutionNoteDialog> createState() => _ResolutionNoteDialogState();
}

class _ResolutionNoteDialogState extends State<_ResolutionNoteDialog> {
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isResolved = widget.status == ReportStatus.resolved;
    
    return AlertDialog(
      title: Text('${isResolved ? 'Resolve' : 'Dismiss'} Report'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add a note about this ${isResolved ? 'resolution' : 'dismissal'} (optional):',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              hintText: isResolved
                  ? 'e.g., Content removed and user warned'
                  : 'e.g., No policy violation found',
              border: const OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final note = _noteController.text.trim();
            Navigator.pop(context, note.isEmpty ? '' : note);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isResolved ? AppColors.success : AppColors.textSecondary,
          ),
          child: Text(isResolved ? 'Resolve' : 'Dismiss'),
        ),
      ],
    );
  }
}
