import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/lesson_display_utils.dart';
import '../models/booking_request.dart';
import '../utils/display_utils.dart';

class BookingCard extends StatelessWidget {
  const BookingCard({super.key, required this.booking});

  final BookingRequest booking;

  Color get _statusColor {
    switch (booking.status) {
      case BookingStatus.pending:
        return AppTheme.statusDraftText;
      case BookingStatus.accepted:
        return AppTheme.statusActiveText;
      case BookingStatus.declined:
        return AppTheme.statusInactiveText;
      case BookingStatus.rescheduled:
        return AppTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.cardDecoration,
      child: InkWell(
        onTap: () => context.push('/skill-provider/booking', extra: booking),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.iconBackground,
                    child: Text(
                      booking.learnerName.isNotEmpty
                          ? booking.learnerName[0]
                          : '?',
                      style: const TextStyle(color: AppTheme.primaryColor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(booking.learnerName,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(formatDate(booking.requestedDate),
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(booking.status.label,
                        style: TextStyle(
                            color: _statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(Icons.menu_book_outlined,
                      size: 16, color: AppTheme.primaryColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      booking.lessonTitle,
                      style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                  if (booking.learnerVerified)
                    const Icon(Icons.verified, size: 16, color: Colors.green),
                ],
              ),
              const SizedBox(height: 4),
              Text(booking.requestedTime,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
