import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../models/verification_request.dart';
import '../services/verification_service.dart';

class VerificationDetailsScreen extends StatefulWidget {
  final String requestId;

  const VerificationDetailsScreen({
    super.key,
    required this.requestId,
  });

  @override
  State<VerificationDetailsScreen> createState() =>
      _VerificationDetailsScreenState();
}

class _VerificationDetailsScreenState extends State<VerificationDetailsScreen> {
  final VerificationService _verificationService = VerificationService();
  VerificationRequest? _request;
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadRequest();
  }

  Future<void> _loadRequest() async {
    setState(() => _isLoading = true);
    
    try {
      final request = await _verificationService.getVerificationRequestById(
          widget.requestId);
      setState(() {
        _request = request;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading request: $e')),
        );
      }
    }
  }

  Future<void> _approveRequest() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Verification'),
        content: const Text(
          'Are you sure you want to approve this verification request?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    try {
      // Mock moderator ID - will be replaced with actual auth user
      await _verificationService.approveVerificationRequest(
        widget.requestId,
        'mod_001',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification approved successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error approving request: $e')),
        );
      }
    }
  }

  Future<void> _rejectRequest() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => const _RejectionDialog(),
    );

    if (result == null || result.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      // Mock moderator ID - will be replaced with actual auth user
      await _verificationService.rejectVerificationRequest(
        widget.requestId,
        'mod_001',
        result,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification rejected'),
            backgroundColor: AppColors.error,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rejecting request: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMMM dd, yyyy - hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _request == null
              ? const Center(child: Text('Request not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Information Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor: AppColors.primaryLight,
                                child: Text(
                                  _request!.userName[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.primaryTeal,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _request!.userName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'User ID: ${_request!.userId}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Verification Type & Status
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailRow(
                                'Verification Type',
                                _request!.verificationType.displayName,
                                Icons.verified_outlined,
                              ),
                              const Divider(height: 24),
                              _buildDetailRow(
                                'Status',
                                _request!.status.displayName,
                                Icons.info_outline,
                                valueColor: _getStatusColor(),
                              ),
                              const Divider(height: 24),
                              _buildDetailRow(
                                'Submitted',
                                dateFormat.format(_request!.submittedAt),
                                Icons.calendar_today,
                              ),
                              if (_request!.reviewedAt != null) ...[
                                const Divider(height: 24),
                                _buildDetailRow(
                                  'Reviewed',
                                  dateFormat.format(_request!.reviewedAt!),
                                  Icons.check_circle_outline,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Identity Verification Details
                      if (_request!.verificationType ==
                          VerificationType.identity) ...[
                        Text(
                          'Identity Information',
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
                                  'Full Name',
                                  _request!.fullName ?? 'Not provided',
                                  Icons.person,
                                ),
                                const Divider(height: 24),
                                const Text(
                                  'Identity Document',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (_request!.identityDocumentUrl != null)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Column(
                                      children: [
                                        const Icon(
                                          Icons.image_outlined,
                                          size: 48,
                                          color: AppColors.textSecondary,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Document Available',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _request!.identityDocumentUrl!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: AppColors.primaryTeal,
                                              ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  const Text(
                                    'No document provided',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // Skill Verification Details
                      if (_request!.verificationType ==
                          VerificationType.skill) ...[
                        Text(
                          'Skill Information',
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
                                  'Skill Name',
                                  _request!.skillName ?? 'Not specified',
                                  Icons.stars,
                                ),
                                const Divider(height: 24),
                                const Text(
                                  'Experience Description',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _request!.experienceDescription ??
                                      'No description provided',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                if (_request!.portfolioUrl != null) ...[
                                  const Divider(height: 24),
                                  _buildDetailRow(
                                    'Portfolio URL',
                                    _request!.portfolioUrl!,
                                    Icons.link,
                                    valueColor: AppColors.primaryTeal,
                                  ),
                                ],
                                if (_request!.evidenceUrls != null &&
                                    _request!.evidenceUrls!.isNotEmpty) ...[
                                  const Divider(height: 24),
                                  const Text(
                                    'Evidence Files',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ..._request!.evidenceUrls!.map(
                                    (url) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppColors.background,
                                          borderRadius: BorderRadius.circular(8),
                                          border:
                                              Border.all(color: AppColors.border),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.attachment,
                                              size: 20,
                                              color: AppColors.primaryTeal,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                url,
                                                style: const TextStyle(
                                                  color: AppColors.primaryTeal,
                                                  fontSize: 13,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],

                      // Rejection Reason (if rejected)
                      if (_request!.status == VerificationStatus.rejected &&
                          _request!.rejectionReason != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Rejection Reason',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          color: AppColors.error.withOpacity(0.05),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: AppColors.error,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _request!.rejectionReason!,
                                    style: const TextStyle(
                                      color: AppColors.error,
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
                      if (_request!.status == VerificationStatus.pending &&
                          !_isProcessing)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _rejectRequest,
                                icon: const Icon(Icons.close),
                                label: const Text('Reject'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                  side: const BorderSide(color: AppColors.error),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _approveRequest,
                                icon: const Icon(Icons.check),
                                label: const Text('Approve'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                          ],
                        ),

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

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
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
                style: TextStyle(
                  color: valueColor ?? AppColors.textPrimary,
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

  Color _getStatusColor() {
    switch (_request!.status) {
      case VerificationStatus.pending:
        return AppColors.pending;
      case VerificationStatus.approved:
        return AppColors.approved;
      case VerificationStatus.rejected:
        return AppColors.rejected;
    }
  }
}

// Rejection Dialog
class _RejectionDialog extends StatefulWidget {
  const _RejectionDialog();

  @override
  State<_RejectionDialog> createState() => _RejectionDialogState();
}

class _RejectionDialogState extends State<_RejectionDialog> {
  String _selectedReason = 'Evidence is unclear';
  final TextEditingController _customReasonController = TextEditingController();

  final List<String> _predefinedReasons = [
    'Evidence is unclear',
    'Insufficient skill evidence',
    'Information does not match',
    'Invalid or inaccessible evidence',
    'Other',
  ];

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reject Verification'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select a rejection reason:'),
            const SizedBox(height: 12),
            ..._predefinedReasons.map(
              (reason) => RadioListTile<String>(
                title: Text(reason),
                value: reason,
                groupValue: _selectedReason,
                onChanged: (value) {
                  setState(() {
                    _selectedReason = value!;
                  });
                },
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
            if (_selectedReason == 'Other') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customReasonController,
                decoration: const InputDecoration(
                  labelText: 'Custom Reason',
                  hintText: 'Enter reason for rejection',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            String reason = _selectedReason;
            if (_selectedReason == 'Other') {
              final customReason = _customReasonController.text.trim();
              if (customReason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a custom reason'),
                  ),
                );
                return;
              }
              reason = customReason;
            }
            Navigator.pop(context, reason);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
          ),
          child: const Text('Reject'),
        ),
      ],
    );
  }
}
