import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../models/moderation_report.dart';

class ReportCard extends StatelessWidget {
  final ModerationReport report;
  final VoidCallback onTap;

  const ReportCard({
    super.key,
    required this.report,
    required this.onTap,
  });

  Color _getStatusColor() {
    switch (report.status) {
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
    switch (report.severity) {
      case ReportSeverity.low:
        return AppColors.severityLow;
      case ReportSeverity.medium:
        return AppColors.severityMedium;
      case ReportSeverity.high:
        return AppColors.severityHigh;
    }
  }

  IconData _getReasonIcon() {
    switch (report.reason) {
      case ReportReason.spam:
        return Icons.report_outlined;
      case ReportReason.harassment:
        return Icons.person_off_outlined;
      case ReportReason.unsafeLocation:
        return Icons.location_off_outlined;
      case ReportReason.inappropriateContent:
        return Icons.block_outlined;
      case ReportReason.fraudScam:
        return Icons.warning_outlined;
      case ReportReason.other:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy - hh:mm a');
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with severity and status
              Row(
                children: [
                  // Severity indicator
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getSeverityColor(),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _getReasonIcon(),
                              size: 18,
                              color: AppColors.textPrimary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              report.reason.displayName,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getSeverityColor().withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${report.severity.displayName} Severity',
                                style: TextStyle(
                                  color: _getSeverityColor(),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getStatusColor().withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                report.status.displayName,
                                style: TextStyle(
                                  color: _getStatusColor(),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              
              // Reported user
              Row(
                children: [
                  const Text(
                    'Reported User: ',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    report.reportedUserName ?? 'Unknown',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              
              // Description
              Text(
                report.description,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              
              // Footer with date and reporter
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(report.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  if (report.reporterName != null)
                    Text(
                      'by ${report.reporterName}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
