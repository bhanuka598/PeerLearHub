import '../models/booking_request.dart';
import '../models/provider_session.dart';

extension BookingStatusDisplay on BookingStatus {
  String get label {
    switch (this) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.accepted:
        return 'Accepted';
      case BookingStatus.declined:
        return 'Declined';
      case BookingStatus.rescheduled:
        return 'Rescheduled';
    }
  }
}

extension SessionStatusDisplay on SessionStatus {
  String get label {
    switch (this) {
      case SessionStatus.upcoming:
        return 'Upcoming';
      case SessionStatus.completed:
        return 'Completed';
      case SessionStatus.cancelled:
        return 'Cancelled';
    }
  }
}

String formatDateTime(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
  final amPm = date.hour >= 12 ? 'PM' : 'AM';
  return '${months[date.month - 1]} ${date.day}, ${date.year} - $hour:${date.minute.toString().padLeft(2, '0')} $amPm';
}
