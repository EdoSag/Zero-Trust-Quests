import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zero_trust_core/zero_trust_core.dart';

/// Quests' own settings for this phone, kept with the core's preferences
/// (not synced: Health Connect and reminders are per phone).
@immutable
class QuestsSettings {
  const QuestsSettings({
    this.useHealth = false,
    this.reminderMinutes,
    this.widgetDetails = false,
    this.workoutAccessDismissed = false,
  });

  /// Fill steps, distance, workouts, sleep and water from Health Connect.
  final bool useHealth;

  /// Daily reminder, minutes after midnight; null for none.
  final int? reminderMinutes;

  /// Step texts and goal names on the home screen widgets (stored
  /// unencrypted on the phone). Off by default.
  final bool widgetDetails;

  /// The Today card asking to read workouts was answered or put away.
  final bool workoutAccessDismissed;

  static const _unset = Object();

  QuestsSettings copyWith({
    bool? useHealth,
    Object? reminderMinutes = _unset,
    bool? widgetDetails,
    bool? workoutAccessDismissed,
  }) => QuestsSettings(
    useHealth: useHealth ?? this.useHealth,
    reminderMinutes: identical(reminderMinutes, _unset)
        ? this.reminderMinutes
        : reminderMinutes as int?,
    widgetDetails: widgetDetails ?? this.widgetDetails,
    workoutAccessDismissed:
        workoutAccessDismissed ?? this.workoutAccessDismissed,
  );
}

final questsSettingsProvider =
    NotifierProvider<QuestsSettingsController, QuestsSettings>(
      QuestsSettingsController.new,
    );

class QuestsSettingsController extends Notifier<QuestsSettings> {
  static const _health = 'quests.useHealth';
  static const _reminder = 'quests.reminder';
  static const _widgetDetails = 'quests.widgetDetails';
  static const _workoutAccess = 'quests.workoutAccessDismissed';

  @override
  QuestsSettings build() {
    _load();
    return const QuestsSettings();
  }

  PreferencesStore get _prefs => ref.read(ztPreferencesStoreProvider);

  Future<void> _load() async {
    try {
      final health = await _prefs.read(_health);
      final reminder = await _prefs.read(_reminder);
      final widgetDetails = await _prefs.read(_widgetDetails);
      final workoutAccess = await _prefs.read(_workoutAccess);
      state = QuestsSettings(
        useHealth: health == 'true',
        reminderMinutes: int.tryParse(reminder ?? ''),
        widgetDetails: widgetDetails == 'true',
        workoutAccessDismissed: workoutAccess == 'true',
      );
    } on Object {
      // Defaults.
    }
  }

  Future<void> setUseHealth(bool on) async {
    state = state.copyWith(useHealth: on);
    await _prefs.write(_health, '$on');
  }

  Future<void> setWidgetDetails(bool on) async {
    state = state.copyWith(widgetDetails: on);
    await _prefs.write(_widgetDetails, '$on');
  }

  Future<void> dismissWorkoutAccess() async {
    state = state.copyWith(workoutAccessDismissed: true);
    await _prefs.write(_workoutAccess, 'true');
  }

  Future<void> setReminder(int? minutes) async {
    state = state.copyWith(reminderMinutes: minutes);
    await _prefs.write(_reminder, minutes == null ? 'off' : '$minutes');
  }
}
