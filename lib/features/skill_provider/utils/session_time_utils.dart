import '../models/provider_session.dart';

Duration parseSessionDuration(String duration) {
  final lower = duration.toLowerCase().trim();
  if (lower.isEmpty) return const Duration(hours: 1);

  final match = RegExp(
    r'(\d+(?:\.\d+)?)\s*(hours?|hrs?|h|minutes?|mins?|m)\b',
  ).firstMatch(lower);
  if (match == null) return const Duration(hours: 1);

  final amount = double.tryParse(match.group(1) ?? '') ?? 1;
  final unit = match.group(2) ?? 'hour';
  if (unit.startsWith('m')) {
    return Duration(minutes: amount.round());
  }
  return Duration(minutes: (amount * 60).round());
}

DateTime sessionEndTime(ProviderSession session) {
  return session.scheduledAt.add(parseSessionDuration(session.duration));
}

bool isWithin24hReminderWindow(DateTime scheduledAt, DateTime now) {
  return !now.isBefore(scheduledAt.subtract(const Duration(hours: 24)));
}

bool isWithin1hReminderWindow(DateTime scheduledAt, DateTime now) {
  return !now.isBefore(scheduledAt.subtract(const Duration(hours: 1)));
}

bool hasSessionEnded(ProviderSession session, [DateTime? now]) {
  return !(now ?? DateTime.now()).isBefore(sessionEndTime(session));
}

/// Combines a calendar date with a time string such as `6:00 PM` or `18:00`.
DateTime combineDateAndTime(DateTime date, String timeText) {
  final parsed = _parseTimeOfDay(timeText);
  return DateTime(
    date.year,
    date.month,
    date.day,
    parsed.$1,
    parsed.$2,
  );
}

(int, int) _parseTimeOfDay(String timeText) {
  final raw = timeText.trim().toUpperCase();
  final match = RegExp(r'(\d{1,2})(?::(\d{2}))?\s*(AM|PM)?').firstMatch(raw);
  if (match == null) return (18, 0);

  var hour = int.tryParse(match.group(1) ?? '') ?? 18;
  final minute = int.tryParse(match.group(2) ?? '') ?? 0;
  final period = match.group(3);

  if (period == 'PM' && hour < 12) hour += 12;
  if (period == 'AM' && hour == 12) hour = 0;
  return (hour.clamp(0, 23), minute.clamp(0, 59));
}
