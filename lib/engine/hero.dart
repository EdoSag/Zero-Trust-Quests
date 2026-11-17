import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../model/days.dart';
import '../model/quest.dart';
import 'engine.dart';

/// Everything the hero has earned, worked out from quests and purchases.
@immutable
class HeroStats {
  const HeroStats({
    required this.xp,
    required this.gold,
    required this.streak,
    required this.bestStreak,
    required this.freezes,
    required this.dailiesDone,
    required this.epicsDone,
    required this.freeDeclineLeft,
    required this.owned,
  });

  static const empty = HeroStats(
    xp: 0,
    gold: 0,
    streak: 0,
    bestStreak: 0,
    freezes: 0,
    dailiesDone: 0,
    epicsDone: 0,
    freeDeclineLeft: true,
    owned: {},
  );

  final int xp;
  final int gold;

  /// Days in a row with at least one completed daily quest, counting today
  /// once one is done (a day without is bridged by a streak freeze).
  final int streak;
  final int bestStreak;

  /// Streak freezes bought and not used yet.
  final int freezes;
  final int dailiesDone;
  final int epicsDone;

  /// One decline a day is free; more cost gold.
  final bool freeDeclineLeft;

  /// Shop items bought (`emblem:x`, `color:x`).
  final Set<String> owned;

  int get level => Levels.levelFor(xp);
  int get xpIntoLevel => xp - Levels.xpAt(level);
  int get xpForNext => Levels.xpAt(level + 1) - Levels.xpAt(level);

  static HeroStats compute(
    List<Quest> quests,
    List<Purchase> purchases,
    String today,
  ) {
    var xp = 0;
    var gold = 0;
    var epics = 0;
    final doneDays = <String, int>{}; // day -> daily XP earned that day
    var dailies = 0;
    var declinedFreeToday = false;
    for (final q in quests) {
      gold -= q.declineCost;
      if (q.isDaily &&
          q.declined != null &&
          q.day == today &&
          q.declineCost == 0) {
        declinedFreeToday = true;
      }
      if (!QuestEngine.completed(q, quests)) continue;
      xp += q.xp;
      gold += q.gold;
      if (q.isDaily) {
        dailies++;
        doneDays[q.day] = (doneDays[q.day] ?? 0) + q.xp;
      } else {
        epics++;
      }
    }
    final freezeDays = <String>[
      for (final p in purchases)
        if (p.item == Shop.freeze) p.day,
    ]..sort();
    final owned = <String>{};
    for (final p in purchases) {
      gold -= p.cost;
      if (p.item != Shop.freeze) owned.add(p.item);
    }

    // Walk the days from the first quest to today.
    var streak = 0;
    var best = 0;
    var freezes = 0;
    var nextFreeze = 0;
    final firstDay = [
      ...doneDays.keys,
      ...freezeDays,
      for (final q in quests)
        if (q.isDaily) q.day,
    ].fold<String?>(null, (a, d) => a == null || d.compareTo(a) < 0 ? d : a);
    if (firstDay != null && firstDay.compareTo(today) <= 0) {
      for (var d = firstDay; d.compareTo(today) <= 0; d = addDays(d, 1)) {
        while (nextFreeze < freezeDays.length &&
            freezeDays[nextFreeze].compareTo(d) <= 0) {
          freezes++;
          nextFreeze++;
        }
        final earned = doneDays[d];
        if (earned != null) {
          streak++;
          // Streak bonus: 5% per day in a row, up to 50%.
          xp += (earned * math.min(streak - 1, 10) * 0.05).floor();
        } else if (d != today) {
          if (streak > 0 && freezes > 0) {
            freezes--;
          } else {
            streak = 0;
          }
        }
        best = math.max(best, streak);
      }
    }
    // Freezes bought after the last day walked (none: today is last).
    freezes += freezeDays.length - nextFreeze;

    return HeroStats(
      xp: xp,
      gold: gold,
      streak: streak,
      bestStreak: best,
      freezes: freezes,
      dailiesDone: dailies,
      epicsDone: epics,
      freeDeclineLeft: !declinedFreeToday,
      owned: owned,
    );
  }
}

/// Level L needs 50 x L x (L - 1) XP: 100 for level 2, 300 for 3, 1000 for
/// 5, 4500 for 10.
abstract final class Levels {
  static int xpAt(int level) => 50 * level * (level - 1);

  static int levelFor(int xp) => math.max(
    1,
    ((50 + math.sqrt(2500 + 200 * math.max(0, xp))) / 100).floor(),
  );

  /// Title ids by the level they start at.
  static const titles = <int, String>{
    1: 'novice',
    3: 'apprentice',
    5: 'adventurer',
    10: 'pathfinder',
    15: 'veteran',
    20: 'hero',
    30: 'champion',
    40: 'master',
    50: 'legend',
  };

  static String titleFor(int level) {
    var t = 'novice';
    for (final e in titles.entries) {
      if (level >= e.key) t = e.value;
    }
    return t;
  }
}

/// Something in the shop: free from [level], or bought for [price] gold.
@immutable
class ShopItem {
  const ShopItem(this.id, {this.level = 1, this.price = 0});

  final String id;
  final int level;
  final int price;
}

abstract final class Shop {
  static const freeze = 'freeze';
  static const freezePrice = 60;
  static const maxFreezes = 3;

  /// Extra declines after the free one of the day.
  static const declinePrice = 10;

  static const emblems = <ShopItem>[
    ShopItem('shield'),
    ShopItem('sword', level: 3),
    ShopItem('flame', level: 5),
    ShopItem('compass', price: 120),
    ShopItem('star', price: 150),
    ShopItem('leaf', price: 150),
    ShopItem('bolt', level: 10),
    ShopItem('rocket', price: 300),
    ShopItem('crown', level: 20),
    ShopItem('diamond', price: 600),
    ShopItem('dragon', level: 30),
    ShopItem('trophy', level: 50),
  ];

  static const colors = <ShopItem>[
    ShopItem('teal'),
    ShopItem('indigo', level: 2),
    ShopItem('rose', price: 80),
    ShopItem('amber', price: 80),
    ShopItem('emerald', level: 5),
    ShopItem('violet', price: 150),
    ShopItem('crimson', level: 15),
    ShopItem('gold', price: 400),
  ];

  static const colorValues = <String, int>{
    'teal': 0xFF14B8A6,
    'indigo': 0xFF6366F1,
    'rose': 0xFFF43F5E,
    'amber': 0xFFF59E0B,
    'emerald': 0xFF10B981,
    'violet': 0xFF8B5CF6,
    'crimson': 0xFFDC2626,
    'gold': 0xFFEAB308,
  };

  /// Whether [item] (`emblem:x` or `color:x`) can be worn.
  static bool unlocked(ShopItem item, String kind, HeroStats stats) =>
      item.price == 0
      ? stats.level >= item.level
      : stats.owned.contains('$kind:${item.id}');
}
