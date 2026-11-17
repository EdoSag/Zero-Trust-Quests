import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

/// The reminder's texts, in the app's language.
class ReminderTexts {
  const ReminderTexts({
    required this.channel,
    required this.title,
    required this.body,
  });
  final String channel;
  final String title;
  final String body;
}

/// "Your quests are waiting", once a day at the chosen time. The text never
/// names a goal or a quest, so nothing private shows on the lock screen.
abstract class DailyReminder {
  Future<bool> requestPermission();

  /// Sets the next [days] reminders at [minutes] after midnight (local
  /// time), skipping today when [skipToday]. Null [minutes] cancels them.
  Future<void> schedule(
    int? minutes,
    ReminderTexts texts, {
    bool skipToday = false,
    int days = 7,
  });
}

class NoopDailyReminder implements DailyReminder {
  int? scheduled;
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<void> schedule(
    int? minutes,
    ReminderTexts texts, {
    bool skipToday = false,
    int days = 7,
  }) async => scheduled = minutes;
}

final dailyReminderProvider = Provider<DailyReminder>(
  (ref) => LocalDailyReminder(FlutterLocalNotificationsPlugin()),
);

class LocalDailyReminder implements DailyReminder {
  LocalDailyReminder(this._plugin);
  final FlutterLocalNotificationsPlugin _plugin;
  Future<void>? _ready;

  static const _firstId = 100;
  static const _maxDays = 14;

  /// Repeats every day after the dated ones, so the reminder keeps coming
  /// when the app stays closed for longer than [days].
  static const _repeatId = _firstId + _maxDays;

  Future<void> _init() => _ready ??= _plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestSoundPermission: false,
        requestBadgePermission: false,
      ),
    ),
  );

  @override
  Future<bool> requestPermission() async {
    await _init();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? true;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, sound: true) ?? false;
    }
    return true;
  }

  @override
  Future<void> schedule(
    int? minutes,
    ReminderTexts texts, {
    bool skipToday = false,
    int days = 7,
  }) async {
    await _init();
    for (var i = 0; i < _maxDays; i++) {
      await _plugin.cancel(id: _firstId + i);
    }
    await _plugin.cancel(id: _repeatId);
    if (minutes == null) return;
    final now = DateTime.now();
    for (var i = 0; i <= days; i++) {
      final at = DateTime(
        now.year,
        now.month,
        now.day + i,
        minutes ~/ 60,
        minutes % 60,
      );
      if (!at.isAfter(now) || (i == 0 && skipToday)) continue;
      // The last one repeats daily at the same time (UTC, so it can drift
      // by an hour over a daylight saving change until the app opens).
      final last = i == days;
      await _plugin.zonedSchedule(
        id: last ? _repeatId : _firstId + i,
        title: texts.title,
        body: texts.body,
        // An absolute instant, so the time zone database doesn't matter.
        scheduledDate: tz.TZDateTime.from(at.toUtc(), tz.UTC),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_quests',
            texts.channel,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: last ? DateTimeComponents.time : null,
      );
    }
  }
}
