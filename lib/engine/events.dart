import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../model/days.dart';
import '../model/quest.dart';

/// A seasonal event: a limited-time epic quest anyone can join while it
/// runs, with an emblem only it gives. Joining saves it as an epic quest
/// (`event-<id>-<start>`, template `event:<id>`, no goal), so it is counted
/// like any epic: from every goal's daily quests and Health Connect.
@immutable
class SeasonalEvent {
  const SeasonalEvent({
    required this.id,
    required this.emblem,
    required this.mode,
    required this.target,
    required this.xp,
    required this.gold,
    this.activity,
  });

  final String id;

  /// The emblem finishing it unlocks (see `Shop.eventEmblems`).
  final String emblem;

  /// [EpicMode.streak]: days with a daily quest done. [EpicMode.total]: the
  /// sum of [activity] over the event.
  final EpicMode mode;
  final String? activity;
  final double target;
  final int xp;
  final int gold;

  static const templatePrefix = 'event:';
  String get template => '$templatePrefix$id';
}

/// One run of an event: its days, both included.
@immutable
class EventRun {
  const EventRun(this.event, this.start, this.end);
  final SeasonalEvent event;
  final String start;
  final String end;

  String get questId => 'event-${event.id}-$start';
  int get days => daysBetween(start, end) + 1;
}

abstract final class SeasonalEvents {
  /// New year, fresh start: a daily quest on 10 of the first 14 days.
  static const newYear = SeasonalEvent(
    id: 'newYear',
    emblem: 'sparkle',
    mode: EpicMode.streak,
    target: 10,
    xp: 250,
    gold: 80,
  );

  /// Hanukkah streak: a daily quest on each of the eight days.
  static const hanukkah = SeasonalEvent(
    id: 'hanukkah',
    emblem: 'candle',
    mode: EpicMode.streak,
    target: 8,
    xp: 300,
    gold: 100,
  );

  /// Summer step challenge: 300,000 steps in July and August.
  static const summerSteps = SeasonalEvent(
    id: 'summerSteps',
    emblem: 'sun',
    mode: EpicMode.total,
    activity: 'walkSteps',
    target: 300000,
    xp: 400,
    gold: 120,
  );

  static const all = [newYear, hanukkah, summerSteps];

  static SeasonalEvent? byId(String id) {
    for (final e in all) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// The event a quest was made from, or null.
  static SeasonalEvent? ofQuest(Quest q) =>
      q.template.startsWith(SeasonalEvent.templatePrefix)
      ? byId(q.template.substring(SeasonalEvent.templatePrefix.length))
      : null;

  /// The first day of Hanukkah (25 Kislev), by Gregorian year. Candles are
  /// lit from the evening before. Worked out from the Hebrew calendar; no
  /// Hanukkah event after the last year listed.
  static const hanukkahStart = <int, String>{
    2025: '2025-12-15',
    2026: '2026-12-05',
    2027: '2027-12-25',
    2028: '2028-12-13',
    2029: '2029-12-02',
    2030: '2030-12-21',
    2031: '2031-12-10',
    2032: '2032-11-28',
    2033: '2033-12-17',
    2034: '2034-12-07',
    2035: '2035-12-26',
  };

  /// The runs of every event in [year].
  static List<EventRun> runsIn(int year) {
    String d(int m, int day) => dayKey(DateTime(year, m, day));
    return [
      EventRun(newYear, d(1, 1), d(1, 14)),
      if (hanukkahStart[year] case final start?)
        EventRun(hanukkah, start, addDays(start, 7)),
      EventRun(summerSteps, d(7, 1), d(8, 31)),
    ];
  }

  /// Events running on [day] (a Hanukkah that started the year before is
  /// still found in early January).
  static List<EventRun> runningOn(String day) {
    final year = dayOf(day).year;
    return [
      for (final y in [year - 1, year])
        for (final r in runsIn(y))
          if (r.start.compareTo(day) <= 0 && r.end.compareTo(day) >= 0) r,
    ];
  }

  /// Running events [quests] has no quest for yet (joined or turned down).
  static List<EventRun> offers(List<Quest> quests, String day) {
    final ids = {for (final q in quests) q.id};
    return [
      for (final r in runningOn(day))
        if (!ids.contains(r.questId)) r,
    ];
  }

  /// The epic quest for joining [run].
  static Quest questFor(EventRun run) {
    final e = run.event;
    return Quest(
      id: run.questId,
      goalId: '',
      kind: QuestKind.epic,
      day: run.start,
      deadline: run.end,
      steps: [
        QuestStep(
          activity: e.mode == EpicMode.streak ? 'streak' : e.activity!,
          target: e.target,
        ),
      ],
      difficulty: 1,
      xp: e.xp,
      gold: math.max(10, e.gold),
      mode: e.mode,
      template: e.template,
    );
  }
}
