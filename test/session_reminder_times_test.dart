import 'package:flutter_test/flutter_test.dart';
import 'package:peer_learn_hub/features/notifications/services/session_reminder_scheduler.dart';
import 'package:peer_learn_hub/features/skill_provider/utils/session_time_utils.dart';

void main() {
  test('device reminders are 24 hours and 1 hour before the session', () {
    final sessionAt = DateTime(2026, 10, 20, 18);
    final now = DateTime(2026, 10, 18, 9);

    final slots = deviceReminderTimes(sessionAt, now);

    expect(slots.map((slot) => slot.kind), ['24h', '1h']);
    expect(slots[0].when, DateTime(2026, 10, 19, 18));
    expect(slots[1].when, DateTime(2026, 10, 20, 17));
  });

  test('a passed reminder is not scheduled again', () {
    final sessionAt = DateTime(2026, 10, 20, 18);
    final now = DateTime(2026, 10, 20, 16, 30);

    final slots = deviceReminderTimes(sessionAt, now);

    expect(slots.map((slot) => slot.kind), ['1h']);
  });

  test('no device reminder is scheduled after the session starts', () {
    final sessionAt = DateTime(2026, 10, 20, 18);
    final now = DateTime(2026, 10, 20, 18);

    expect(deviceReminderTimes(sessionAt, now), isEmpty);
  });

  test('reminder ids stay stable for the same session', () {
    expect(
      deviceReminderId('session_from_booking', '24h'),
      deviceReminderId('session_from_booking', '24h'),
    );
    expect(
      deviceReminderId('session_from_booking', '24h'),
      isNot(deviceReminderId('session_from_booking', '1h')),
    );
  });
}
