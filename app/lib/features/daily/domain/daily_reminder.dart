class DailyReminder {
  const DailyReminder({
    required this.enabled,
    required this.hour,
    required this.minute,
  });

  static const defaults = DailyReminder(enabled: false, hour: 20, minute: 0);

  final bool enabled;
  final int hour;
  final int minute;

  DailyReminder copyWith({bool? enabled, int? hour, int? minute}) {
    return DailyReminder(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }
}
