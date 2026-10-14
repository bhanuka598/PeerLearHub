import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/lesson_display_utils.dart';
import '../models/booking_request.dart';
import '../services/booking_service.dart';
import '../utils/display_utils.dart';
import '../widgets/app_header.dart';

class BookingDetailsScreen extends StatelessWidget {
  const BookingDetailsScreen({super.key, required this.booking});

  final BookingRequest booking;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const TealPageHeader(title: 'Booking Details'),
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
                  Text(booking.learnerName,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  if (booking.learnerVerified)
                    const Row(
                      children: [
                        Icon(Icons.verified, color: Colors.green, size: 16),
                        SizedBox(width: 4),
                        Text('Verified Learner',
                            style: TextStyle(color: Colors.green, fontSize: 13)),
                      ],
                    ),
                  const Divider(height: 24),
                  _row('Lesson', booking.lessonTitle),
                  _row('Date', formatDate(booking.requestedDate)),
                  _row('Time', booking.requestedTime),
                  _row('Status', booking.status.label),
                  if (booking.message != null) ...[
                    const SizedBox(height: 12),
                    const Text('Message',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(booking.message!),
                  ],
                ],
              ),
            ),
            if (booking.status == BookingStatus.pending) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await BookingService.instance.acceptBooking(booking.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Booking accepted.')));
                    context.pop();
                  }
                },
                child: const Text('Accept'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () async {
                  await BookingService.instance.declineBooking(booking.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Booking declined.')));
                    context.pop();
                  }
                },
                child: const Text('Decline'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => context.push('/skill-provider/reschedule',
                    extra: booking),
                child: const Text('Reschedule'),
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
        children: [
          SizedBox(
              width: 80,
              child: Text(label,
                  style: const TextStyle(color: AppTheme.textSecondary))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
