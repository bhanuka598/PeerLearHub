import 'package:flutter/material.dart';
import '../models/skill_exchange_models.dart';

class ExchangeRequestCard extends StatelessWidget {
  final SkillExchangeRequest request;
  final bool isIncoming;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onCancel;

  const ExchangeRequestCard({
    super.key,
    required this.request,
    required this.isIncoming,
    this.onApprove,
    this.onReject,
    this.onCancel,
  });

  Color _getStatusColor(ExchangeStatus status) {
    switch (status) {
      case ExchangeStatus.pendingPeerApproval:
        return Colors.orange.shade700;
      case ExchangeStatus.pendingTutorApproval:
        return Colors.amber.shade800;
      case ExchangeStatus.approved:
        return Colors.green.shade700;
      case ExchangeStatus.rejected:
        return Colors.red.shade700;
      case ExchangeStatus.completed:
        return Colors.blue.shade700;
      case ExchangeStatus.cancelled:
        return Colors.grey.shade600;
    }
  }

  String _getStatusText(ExchangeStatus status) {
    switch (status) {
      case ExchangeStatus.pendingPeerApproval:
        return 'Pending Peer Tutor Approval';
      case ExchangeStatus.pendingTutorApproval:
        return 'Pending Tutor Approval (Student Initiated)';
      case ExchangeStatus.approved:
        return 'Approved & Swapped';
      case ExchangeStatus.rejected:
        return 'Rejected';
      case ExchangeStatus.completed:
        return 'Completed';
      case ExchangeStatus.cancelled:
        return 'Cancelled';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(request.status);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withAlpha(80), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header & AI Score Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getStatusText(request.status),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.teal.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, size: 12, color: Colors.teal),
                      const SizedBox(width: 4),
                      Text(
                        '${request.matchScore.toStringAsFixed(0)}% Match',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Swap Overview (Offered <-> Requested)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.arrow_upward_rounded, size: 18, color: Colors.redAccent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isIncoming ? 'Offered to You:' : 'You Offered:',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                            Text(
                              request.offeredCourseTitle,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Divider(height: 1, color: Colors.grey.shade300),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.arrow_downward_rounded, size: 18, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isIncoming ? 'Requested from You:' : 'You Requested:',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                            Text(
                              request.requestedCourseTitle,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Message text
            if (request.message.isNotEmpty) ...[
              Text(
                '"${request.message}"',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 12),
            ],

            // User Info and Actions
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundImage: NetworkImage(
                    isIncoming ? request.requesterAvatar : request.targetOwnerAvatar,
                  ),
                  onBackgroundImageError: (_, __) {},
                  child: const Icon(Icons.person, size: 14),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isIncoming ? request.requesterName : request.targetOwnerName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                      Text(
                        isIncoming
                            ? 'Role: ${request.requesterRole.name.toUpperCase()}'
                            : 'Target Instructor',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),

                // Approval actions for incoming pending requests
                if (isIncoming &&
                    (request.status == ExchangeStatus.pendingPeerApproval ||
                        request.status == ExchangeStatus.pendingTutorApproval)) ...[
                  OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: const Text('Decline', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: onApprove,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    ),
                    child: const Text('Approve', style: TextStyle(fontSize: 12)),
                  ),
                ] else if (!isIncoming &&
                    (request.status == ExchangeStatus.pendingPeerApproval ||
                        request.status == ExchangeStatus.pendingTutorApproval)) ...[
                  OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: const Text('Cancel Request', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
