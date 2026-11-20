import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/daily_reminder_scheduler.dart';
import '../../../core/providers/key_value_storage_provider.dart';
import '../../../i18n/strings.g.dart';
import '../domain/daily_reminder.dart';

const _enabledKey = 'daily.reminder.enabled';
const _hourKey = 'daily.reminder.hour';
const _minuteKey = 'daily.reminder.minute';

final dailyReminderSchedulerProvider = Provider<DailyReminderScheduler>((ref) {
  return LocalDailyReminderScheduler();
});

final dailyReminderProvider =
    AsyncNotifierProvider<DailyReminderController, DailyReminder>(
      DailyReminderController.new,
    );

class DailyReminderController extends AsyncNotifier<DailyReminder> {
  @override
  Future<DailyReminder> build() async {
    final storage = ref.read(keyValueStorageProvider);
    final enabled = await storage.getBool(_enabledKey) ?? false;
    final hour = await storage.getInt(_hourKey) ?? DailyReminder.defaults.hour;
    final minute =
        await storage.getInt(_minuteKey) ?? DailyReminder.defaults.minute;
    final reminder = DailyReminder(
      enabled: enabled,
      hour: hour.clamp(0, 23),
      minute: minute.clamp(0, 59),
    );
    if (reminder.enabled) {
      await _schedule(reminder);
    }
    return reminder;
  }

  Future<bool> setEnabled(bool enabled) async {
    final current = state.value ?? DailyReminder.defaults;
    if (enabled) {
      final granted = await ref
          .read(dailyReminderSchedulerProvider)
          .requestPermission();
      if (!granted) {
        return false;
      }
    }
    final next = current.copyWith(enabled: enabled);
    state = AsyncData(next);
    final storage = ref.read(keyValueStorageProvider);
    await storage.setBool(_enabledKey, enabled);
    await storage.setInt(_hourKey, next.hour);
    await storage.setInt(_minuteKey, next.minute);
    if (enabled) {
      await _schedule(next);
    } else {
      await ref.read(dailyReminderSchedulerProvider).cancel();
    }
    return true;
  }

  Future<void> setTime(int hour, int minute) async {
    final current = state.value ?? DailyReminder.defaults;
    final next = current.copyWith(hour: hour, minute: minute);
    state = AsyncData(next);
    final storage = ref.read(keyValueStorageProvider);
    await storage.setInt(_hourKey, hour);
    await storage.setInt(_minuteKey, minute);
    if (next.enabled) {
      await _schedule(next);
    }
  }

  Future<void> _schedule(DailyReminder reminder) async {
    final t = LocaleSettings.currentLocale.buildSync().daily;
    await ref
        .read(dailyReminderSchedulerProvider)
        .schedule(
          hour: reminder.hour,
          minute: reminder.minute,
          title: t.reminderTitle,
          body: t.reminderBody,
        );
  }
}
