import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zero_trust_core/zero_trust_core.dart';

/// Quests' own settings for this phone, kept with the core's preferences
/// (not synced: Health Connect and reminders are per phone).
@immutable
class QuestsSettings {
  const QuestsSettings({this.useHealth = false, this.reminderMinutes});

  /// Fill steps, distance, workouts, sleep and water from Health Connect.
  final bool useHealth;

  /// Daily reminder, minutes after midnight; null for none.
  final int? reminderMinutes;

  static const _unset = Object();

  QuestsSettings copyWith({
    bool? useHealth,
    Object? reminderMinutes = _unset,
  }) => QuestsSettings(
    useHealth: useHealth ?? this.useHealth,
    reminderMinutes: identical(reminderMinutes, _unset)
        ? this.reminderMinutes
        : reminderMinutes as int?,
  );
}

final questsSettingsProvider =
    NotifierProvider<QuestsSettingsController, QuestsSettings>(
      QuestsSettingsController.new,
    );

class QuestsSettingsController extends Notifier<QuestsSettings> {
  static const _health = 'quests.useHealth';
  static const _reminder = 'quests.reminder';

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
      state = QuestsSettings(
        useHealth: health == 'true',
        reminderMinutes: int.tryParse(reminder ?? ''),
      );
    } on Object {
      // Defaults.
    }
  }

  Future<void> setUseHealth(bool on) async {
    state = state.copyWith(useHealth: on);
    await _prefs.write(_health, '$on');
  }

  Future<void> setReminder(int? minutes) async {
    state = state.copyWith(reminderMinutes: minutes);
    await _prefs.write(_reminder, minutes == null ? 'off' : '$minutes');
  }
}
