import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/core/notifications/daily_reminder_scheduler.dart';
import 'package:named/core/providers/key_value_storage_provider.dart';
import 'package:named/features/daily/providers/daily_reminder_provider.dart';
import 'package:named/i18n/strings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeScheduler implements DailyReminderScheduler {
  var permission = true;
  var scheduled = 0;
  var cancelled = 0;
  int? hour;
  int? minute;
  String? title;

  @override
  Future<bool> requestPermission() async => permission;

  @override
  Future<void> schedule({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    scheduled++;
    this.hour = hour;
    this.minute = minute;
    this.title = title;
  }

  @override
  Future<void> cancel() async {
    cancelled++;
  }
}

void main() {
  setUp(() async {
    await LocaleSettings.setLocale(AppLocale.en);
  });

  test('persists and schedules a daily reminder', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final scheduler = _FakeScheduler();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        dailyReminderSchedulerProvider.overrideWithValue(scheduler),
      ],
    );
    addTearDown(container.dispose);

    final initial = await container.read(dailyReminderProvider.future);
    expect(initial.enabled, isFalse);

    expect(
      await container.read(dailyReminderProvider.notifier).setEnabled(true),
      isTrue,
    );
    expect(container.read(dailyReminderProvider).value?.enabled, isTrue);
    expect(scheduler.scheduled, 1);
    expect(scheduler.hour, 20);

    await container.read(dailyReminderProvider.notifier).setTime(7, 45);
    expect(scheduler.scheduled, 2);
    expect(scheduler.hour, 7);
    expect(scheduler.minute, 45);
    expect(prefs.getInt('daily.reminder.hour'), 7);
    expect(prefs.getInt('daily.reminder.minute'), 45);

    await container.read(dailyReminderProvider.notifier).setEnabled(false);
    expect(scheduler.cancelled, 1);
    expect(prefs.getBool('daily.reminder.enabled'), isFalse);
  });

  test('does not enable when permission is denied', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final scheduler = _FakeScheduler()..permission = false;
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        dailyReminderSchedulerProvider.overrideWithValue(scheduler),
      ],
    );
    addTearDown(container.dispose);

    await container.read(dailyReminderProvider.future);
    expect(
      await container.read(dailyReminderProvider.notifier).setEnabled(true),
      isFalse,
    );
    expect(container.read(dailyReminderProvider).value?.enabled, isFalse);
    expect(scheduler.scheduled, 0);
  });
}
