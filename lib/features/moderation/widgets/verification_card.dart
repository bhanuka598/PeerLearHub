import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../models/verification_request.dart';

class VerificationCard extends StatelessWidget {
  final VerificationRequest request;
  final VoidCallback onTap;

  const VerificationCard({
    super.key,
    required this.request,
    required this.onTap,
  });

  Color _getStatusColor() {
    switch (request.status) {
      case VerificationStatus.pending:
        return AppColors.pending;
      case VerificationStatus.approved:
        return AppColors.approved;
      case VerificationStatus.rejected:
        return AppColors.rejected;
    }
  }

  IconData _getVerificationIcon() {
    switch (request.verificationType) {
      case VerificationType.identity:
        return Icons.person_outline;
      case VerificationType.skill:
        return Icons.verified_outlined;
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
              // Header with user info
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      request.userName[0].toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.primaryTeal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.userName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateFormat.format(request.submittedAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _getStatusColor(), width: 1),
                    ),
                    child: Text(
                      request.status.displayName,
                      style: TextStyle(
                        color: _getStatusColor(),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              
              // Verification details
              Row(
                children: [
                  Icon(
                    _getVerificationIcon(),
                    size: 20,
                    color: AppColors.primaryTeal,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    request.verificationType.displayName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.primaryTeal,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
              
              // Skill name for skill verification
              if (request.verificationType == VerificationType.skill &&
                  request.skillName != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Skill: ${request.skillName}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
              
              // Show rejection reason if rejected
              if (request.status == VerificationStatus.rejected &&
                  request.rejectionReason != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          request.rejectionReason!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.error,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
