import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../engine/engine.dart';
import '../engine/hero.dart';
import '../l10n/l10n.dart';
import '../model/goal.dart';
import '../model/quest.dart';
import '../ui/labels.dart';

/// What the Android home screen widgets show (`QuestsWidgetData.kt`): today's
/// quest, the hero card, the streak and the next step.
///
/// The widgets live outside the vault, so what is written here is stored
/// unencrypted on the phone. By default that is only numbers: level, XP,
/// gold, streak, and how many of today's steps are done. Step texts and goal
/// names are written only with "Show details on the home screen" on, and
/// are removed again when it is turned off or the account signs out.
abstract final class QuestsWidgetContent {
  /// The JSON the widgets read (see `QuestsWidgetData.kt`).
  static Map<String, Object?> build({
    required List<Goal> goals,
    required List<Quest> quests,
    required HeroStats stats,
    required String day,
    required bool details,
    required AppL10n l,
  }) {
    final todays = <Map<String, Object?>>[];
    for (final g in goals) {
      if (g.archived) continue;
      final q = QuestEngine.currentDaily(g.id, quests, day);
      if (q == null || q.declined != null) continue;
      todays.add({
        'id': q.id,
        'goal': details ? goalName(l, g) : '',
        'xp': q.xp,
        'gold': q.gold,
        'steps': [
          for (final s in q.steps)
            {'t': details ? stepText(l, s) : '', 'done': s.done},
        ],
      });
    }
    final todayDone = quests.any(
      (q) => q.isDaily && q.day == day && QuestEngine.completed(q, quests),
    );
    return {
      'day': day,
      'details': details,
      'xp': stats.xp,
      'gold': stats.gold,
      'streak': stats.streak,
      'freezes': stats.freezes,
      'todayDone': todayDone,
      'titles': [
        for (final level in Levels.titles.keys) [level, heroTitle(l, level)],
      ],
      'quests': todays,
    };
  }

  /// The widgets' own words, in the language picked in the app. Numbers are
  /// filled in on the widget (`%d`), since a tick there changes them.
  static Map<String, String> texts(AppL10n l) => {
    'today_title': l.widgetTodayTitle,
    'steps_done': l.widgetStepsDone(r'%1$d', r'%2$d'),
    'all_done': l.widgetAllDone,
    'signed_out': l.widgetSignedOut,
    'open_to_see': l.widgetOpenToSee,
    'new_day': l.widgetNewDay,
    'no_quests': l.widgetNoQuests,
    'complete_step': l.widgetCompleteStep,
    'level': l.widgetLevel('%d'),
    'xp': l.widgetXp(r'%1$d', r'%2$d'),
    'gold': l.widgetGold('%d'),
    'streak': l.widgetStreak,
    'streak_warn': l.widgetStreakWarn,
    'streak_done': l.widgetStreakDone,
    'next_step': l.widgetNextStep,
    'steps_left': l.widgetStepsLeft('%d'),
    'open_app': l.widgetOpenApp,
  };
}

/// A step ticked on a widget, waiting for the unlocked app.
@immutable
class WidgetTick {
  const WidgetTick(this.seq, this.questId, this.step);

  /// The widget's running number for this tick; the app records the last
  /// one it saved, so the widget can drop it from its queue.
  final int seq;
  final String questId;
  final int step;

  /// One line, as `QuestsWidgetData.kt` writes it:
  /// `<number>|<quest id>|<step>`. Null when unreadable.
  static WidgetTick? parse(String line) {
    final first = line.indexOf('|');
    final last = line.lastIndexOf('|');
    if (first <= 0 || last <= first + 1) return null;
    final seq = int.tryParse(line.substring(0, first).trim());
    final step = int.tryParse(line.substring(last + 1).trim());
    if (seq == null || step == null || step < 0) return null;
    return WidgetTick(seq, line.substring(first + 1, last).trim(), step);
  }

  /// [quest] with this step done, or null when there is nothing to do: not
  /// a daily quest, declined, no such step, or already done (the app or
  /// Health Connect got there first). The widget only ticks the day's own
  /// quests, so a tick saved after midnight still counts for its day.
  Quest? applyTo(Quest quest) {
    if (quest.id != questId || !quest.isDaily) return null;
    if (quest.declined != null || step >= quest.steps.length) return null;
    final s = quest.steps[step];
    if (s.done) return null;
    final steps = [...quest.steps]..[step] = s.withProgress(s.target);
    return quest.copyWith(steps: steps);
  }
}

final questsWidgetsProvider = Provider<QuestsWidgets>(
  (ref) => const QuestsWidgets(),
);

/// Writes the widgets' content and reads the ticks made on them.
class QuestsWidgets {
  const QuestsWidgets();

  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static const _providers = [
    'dev.sagron.zerotrustquests.widgets.TodayQuestWidgetProvider',
    'dev.sagron.zerotrustquests.widgets.HeroWidgetProvider',
    'dev.sagron.zerotrustquests.widgets.StreakWidgetProvider',
    'dev.sagron.zerotrustquests.widgets.NextStepWidgetProvider',
  ];
  static const _dataKey = 'quests_widget_data';
  static const _signedOutKey = 'quests_widget_signed_out';
  static const _queueKey = 'quests_widget_pending';
  static const _seqKey = 'quests_widget_seq';
  static const _ackKey = 'quests_widget_ack';

  /// Shows [content] ([QuestsWidgetContent.build]) with [texts].
  Future<void> publish(
    Map<String, Object?> content,
    Map<String, String> texts,
  ) async {
    if (!isSupported) return;
    try {
      await HomeWidget.saveWidgetData<bool>(_signedOutKey, false);
      await HomeWidget.saveWidgetData<String>(_dataKey, jsonEncode(content));
      for (final MapEntry(:key, :value) in texts.entries) {
        await HomeWidget.saveWidgetData<String>(
          'quests_widget_text_$key',
          value,
        );
      }
      await _redraw();
    } on Object catch (e) {
      debugPrint('Quests widgets not updated: $e');
    }
  }

  /// Signed out: a lock on every widget, and nothing of the account left.
  /// Ticks still queued are marked as handled, so they never reach the
  /// next account.
  Future<void> signedOut() async {
    if (!isSupported) return;
    try {
      await HomeWidget.saveWidgetData<bool>(_signedOutKey, true);
      await HomeWidget.saveWidgetData<String>(_dataKey, null);
      final seq = await HomeWidget.getWidgetData<String>(_seqKey);
      if (seq != null) {
        await HomeWidget.saveWidgetData<String>(_ackKey, seq);
      }
      await _redraw();
    } on Object catch (e) {
      debugPrint('Quests widgets not updated: $e');
    }
  }

  Future<void> _redraw() async {
    for (final p in _providers) {
      await HomeWidget.updateWidget(qualifiedAndroidName: p);
    }
  }

  /// Ticks made on the widgets and not yet saved, oldest first. Each stays
  /// queued until [acknowledge]d, so a tick is not lost if saving it fails.
  ///
  /// Only the widget writes the queue; the app writes only the number of
  /// the last tick it saved, so a tick made while the app reads is never
  /// overwritten.
  Future<List<WidgetTick>> pending() async {
    if (!isSupported) return const [];
    try {
      final queue = await HomeWidget.getWidgetData<String>(_queueKey);
      final acked =
          int.tryParse(await HomeWidget.getWidgetData<String>(_ackKey) ?? '') ??
          0;
      return [
        for (final line in (queue ?? '').split('\n'))
          if (WidgetTick.parse(line) case final t? when t.seq > acked) t,
      ]..sort((a, b) => a.seq.compareTo(b.seq));
    } on Object {
      return const [];
    }
  }

  /// Records [tick] and every one before it as saved.
  Future<void> acknowledge(WidgetTick tick) async {
    if (!isSupported) return;
    await HomeWidget.saveWidgetData<String>(_ackKey, '${tick.seq}');
  }
}
