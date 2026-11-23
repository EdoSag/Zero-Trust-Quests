import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'hero.dart';

/// What an achievement counts.
enum AchievementMetric {
  dailies,
  bestStreak,
  epics,
  level,
  tasks,
  partyWins,
  events,
  purchases,
}

/// One achievement: reach [target] of [metric]. Worked out from the hero's
/// stats every time, never stored, so every phone shows the same.
@immutable
class Achievement {
  const Achievement(this.id, this.metric, this.target);
  final String id;
  final AchievementMetric metric;
  final int target;
}

@immutable
class AchievementProgress {
  const AchievementProgress(this.achievement, this.value);
  final Achievement achievement;
  final int value;

  bool get unlocked => value >= achievement.target;
  double get ratio => (value / achievement.target).clamp(0, 1).toDouble();
  int get shown => math.min(value, achievement.target);
}

abstract final class Achievements {
  static const all = <Achievement>[
    Achievement('firstQuest', AchievementMetric.dailies, 1),
    Achievement('dailies10', AchievementMetric.dailies, 10),
    Achievement('dailies50', AchievementMetric.dailies, 50),
    Achievement('dailies100', AchievementMetric.dailies, 100),
    Achievement('dailies365', AchievementMetric.dailies, 365),
    Achievement('streak3', AchievementMetric.bestStreak, 3),
    Achievement('streak7', AchievementMetric.bestStreak, 7),
    Achievement('streak30', AchievementMetric.bestStreak, 30),
    Achievement('streak100', AchievementMetric.bestStreak, 100),
    Achievement('firstEpic', AchievementMetric.epics, 1),
    Achievement('epics10', AchievementMetric.epics, 10),
    Achievement('level5', AchievementMetric.level, 5),
    Achievement('level10', AchievementMetric.level, 10),
    Achievement('level25', AchievementMetric.level, 25),
    Achievement('tasks10', AchievementMetric.tasks, 10),
    Achievement('tasks100', AchievementMetric.tasks, 100),
    Achievement('firstBoss', AchievementMetric.partyWins, 1),
    Achievement('bosses10', AchievementMetric.partyWins, 10),
    Achievement('firstEvent', AchievementMetric.events, 1),
    Achievement('firstPurchase', AchievementMetric.purchases, 1),
  ];

  static int valueOf(AchievementMetric m, HeroStats s) => switch (m) {
    AchievementMetric.dailies => s.dailiesDone,
    AchievementMetric.bestStreak => s.bestStreak,
    AchievementMetric.epics => s.epicsDone,
    AchievementMetric.level => s.level,
    AchievementMetric.tasks => s.tasksDone,
    AchievementMetric.partyWins => s.partyWins,
    AchievementMetric.events => s.eventsDone,
    AchievementMetric.purchases => s.purchasesMade,
  };

  static List<AchievementProgress> of(HeroStats s) => [
    for (final a in all) AchievementProgress(a, valueOf(a.metric, s)),
  ];
}
