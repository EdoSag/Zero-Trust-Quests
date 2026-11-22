import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../engine/engine.dart';
import '../engine/hero.dart';
import '../model/days.dart';
import '../model/quest.dart';
import '../model/reward.dart';

/// How hard a party's bosses are: hit points per member per day. A daily
/// quest done hits for [PartyRules.dailyHit], so "normal" asks about one and
/// a half quests a day from everyone.
enum PartyDifficulty {
  easy(10),
  normal(15),
  hard(20);

  const PartyDifficulty(this.hpPerMemberDay);
  final int hpPerMemberDay;

  static PartyDifficulty parse(Object? v) => PartyDifficulty.values.firstWhere(
    (d) => d.name == v,
    orElse: () => PartyDifficulty.normal,
  );
}

/// The bosses a party hunts, one after another.
const partyBosses = [
  'slime',
  'goblin',
  'troll',
  'golem',
  'wyvern',
  'kraken',
  'lich',
  'dragon',
];

abstract final class PartyRules {
  /// Damage of a daily quest done.
  static const dailyHit = 10;

  /// Damage of a ZT Tasks task that earned XP.
  static const taskHit = 2;

  /// Days after a hunt ends that phones still send their damage (a quest
  /// finished late, a phone that was offline on the last day).
  static const graceDays = 3;

  static const lengths = [3, 7, 14];

  static int rewardXp(int days) => 40 + 10 * days;
  static int rewardGold(int days) => math.max(10, rewardXp(days) ~/ 3);
}

/// A boss the party beat, kept on the party after the next hunt starts so
/// that a helper whose phone was offline still gets the reward. [helpers]
/// are the members who had hit it when the owner moved on.
@immutable
class PastHunt {
  const PastHunt({
    required this.round,
    required this.boss,
    required this.days,
    this.helpers = const [],
  });

  final int round;
  final String boss;
  final int days;
  final List<String> helpers;

  Map<String, Object?> toJson() => {
    'round': round,
    'boss': boss,
    'days': days,
    'helpers': helpers,
  };

  static PastHunt? fromJson(Object? j) {
    if (j is! Map) return null;
    final round = (j['round'] as num?)?.toInt() ?? 0;
    final days = (j['days'] as num?)?.toInt() ?? 0;
    if (round <= 0 || days <= 0) return null;
    return PastHunt(
      round: round,
      boss: (j['boss'] as String?) ?? '',
      days: days,
      helpers: [
        for (final h in (j['helpers'] as List?) ?? const [])
          if (h is String) h,
      ],
    );
  }
}

/// A party: friends on one end-to-end encrypted shared space, hunting one
/// boss at a time. Only the party's owners change it (item [itemId], kind
/// [kind], admin-only).
@immutable
class Party {
  const Party({
    required this.name,
    this.difficulty = PartyDifficulty.normal,
    this.round = 0,
    this.boss = '',
    this.start = '',
    this.end = '',
    this.won = const [],
  });

  static const itemId = 'party';

  /// How many beaten hunts a party keeps for helpers who were offline.
  static const keepWon = 5;
  static const kind = 'party';

  final String name;
  final PartyDifficulty difficulty;

  /// The current hunt, counting from 1; 0 before the first.
  final int round;
  final String boss;

  /// The hunt's days, both included.
  final String start;
  final String end;

  /// Recently beaten hunts, newest last.
  final List<PastHunt> won;

  bool get hasHunt => round > 0 && start.isNotEmpty && end.isNotEmpty;
  int get days => hasHunt ? daysBetween(start, end) + 1 : 0;

  bool runningOn(String day) =>
      hasHunt && start.compareTo(day) <= 0 && end.compareTo(day) >= 0;

  /// Phones still send damage for this hunt on [day].
  bool scoringOn(String day) =>
      hasHunt &&
      start.compareTo(day) <= 0 &&
      addDays(end, PartyRules.graceDays).compareTo(day) >= 0;

  /// The boss's hit points with [members] people in the party.
  int hp(int members) =>
      difficulty.hpPerMemberDay * days * math.max(1, members);

  /// The next hunt, from [day], [days] long. The boss follows the last one.
  Party nextHunt(String day, int days, {String salt = ''}) {
    final next = round + 1;
    final pick = (QuestEngine.hash(salt) + next) % partyBosses.length;
    return Party(
      name: name,
      difficulty: difficulty,
      round: next,
      boss: partyBosses[pick],
      start: day,
      end: addDays(day, days - 1),
      won: won,
    );
  }

  /// Keeps [hunt], beaten, with everyone who hit it, before the next hunt
  /// replaces it.
  Party rememberWin(HuntState hunt) {
    if (!hunt.defeated || hunt.party.round != round) return this;
    final entry = PastHunt(
      round: round,
      boss: boss,
      days: days,
      helpers: [
        for (final s in hunt.board)
          if (s.damage > 0) s.userId,
      ],
    );
    final kept = [
      for (final w in won)
        if (w.round != round) w,
      entry,
    ];
    return Party(
      name: name,
      difficulty: difficulty,
      round: round,
      boss: boss,
      start: start,
      end: end,
      won: kept.length > keepWon ? kept.sublist(kept.length - keepWon) : kept,
    );
  }

  Party copyWith({String? name, PartyDifficulty? difficulty}) => Party(
    name: name ?? this.name,
    difficulty: difficulty ?? this.difficulty,
    round: round,
    boss: boss,
    start: start,
    end: end,
    won: won,
  );

  Map<String, Object?> toJson() => {
    'kind': kind,
    'name': name,
    'difficulty': difficulty.name,
    'round': round,
    'boss': boss,
    'start': start,
    'end': end,
    if (won.isNotEmpty) 'won': [for (final w in won) w.toJson()],
  };

  static Party fromJson(Map<String, Object?> j) => Party(
    name: (j['name'] as String?) ?? '',
    difficulty: PartyDifficulty.parse(j['difficulty']),
    round: (j['round'] as num?)?.toInt() ?? 0,
    boss: (j['boss'] as String?) ?? '',
    start: (j['start'] as String?) ?? '',
    end: (j['end'] as String?) ?? '',
    won: [
      for (final w in (j['won'] as List?) ?? const [])
        if (PastHunt.fromJson(w) case final p?) p,
    ],
  );
}

/// What one member shares with the party about the current hunt: the
/// damage their quests did, and how their hero looks. Item
/// `member/<userId>`, which only that member can write.
@immutable
class PartyMember {
  const PartyMember({
    required this.userId,
    required this.round,
    this.damage = 0,
    this.dailies = 0,
    this.tasks = 0,
    this.level = 1,
    this.emblem = 'shield',
    this.color = 'teal',
  });

  static const prefix = 'member/';
  static const kind = 'party_member';
  static String itemIdFor(String userId) => '$prefix$userId';

  final String userId;

  /// The hunt these numbers are for.
  final int round;
  final int damage;
  final int dailies;
  final int tasks;
  final int level;
  final String emblem;
  final String color;

  bool sameAs(PartyMember? o) =>
      o != null &&
      o.round == round &&
      o.damage == damage &&
      o.dailies == dailies &&
      o.tasks == tasks &&
      o.level == level &&
      o.emblem == emblem &&
      o.color == color;

  Map<String, Object?> toJson() => {
    'kind': kind,
    'round': round,
    'damage': damage,
    'dailies': dailies,
    'tasks': tasks,
    'level': level,
    'emblem': emblem,
    'color': color,
  };

  static PartyMember? fromJson(String itemId, Map<String, Object?>? j) {
    if (j == null || !itemId.startsWith(prefix)) return null;
    final userId = itemId.substring(prefix.length);
    if (userId.isEmpty || userId.contains('/')) return null;
    return PartyMember(
      userId: userId,
      round: (j['round'] as num?)?.toInt() ?? 0,
      damage: math.max(0, (j['damage'] as num?)?.toInt() ?? 0),
      dailies: (j['dailies'] as num?)?.toInt() ?? 0,
      tasks: (j['tasks'] as num?)?.toInt() ?? 0,
      level: (j['level'] as num?)?.toInt() ?? 1,
      emblem: (j['emblem'] as String?) ?? 'shield',
      color: (j['color'] as String?) ?? 'teal',
    );
  }

  /// This account's numbers for [party]'s current hunt, from its own
  /// quests and rewards.
  static PartyMember compute({
    required String userId,
    required Party party,
    required List<Quest> quests,
    required List<Reward> rewards,
    required HeroStats stats,
    required HeroLook look,
  }) {
    bool inHunt(String d) =>
        d.compareTo(party.start) >= 0 && d.compareTo(party.end) <= 0;
    var dailies = 0;
    for (final q in quests) {
      if (q.isDaily && inHunt(q.day) && QuestEngine.completed(q, quests)) {
        dailies++;
      }
    }
    // The same per-day cap as the XP.
    final perDay = <String, int>{};
    var tasks = 0;
    for (final r in [...rewards]..sort((a, b) => a.id.compareTo(b.id))) {
      if (r.source != RewardSource.task || !inHunt(r.day)) continue;
      final n = perDay[r.day] = (perDay[r.day] ?? 0) + 1;
      if (n <= HeroStats.tasksPerDay) tasks++;
    }
    return PartyMember(
      userId: userId,
      round: party.round,
      damage: dailies * PartyRules.dailyHit + tasks * PartyRules.taskHit,
      dailies: dailies,
      tasks: tasks,
      level: stats.level,
      emblem: look.emblem,
      color: look.color,
    );
  }
}

/// One row of the party board.
@immutable
class PartyStanding {
  const PartyStanding({required this.userId, required this.name, this.member});
  final String userId;
  final String name;

  /// Null until their phone has sent numbers for this hunt.
  final PartyMember? member;

  int get damage => member?.damage ?? 0;
}

/// How a hunt stands.
@immutable
class HuntState {
  const HuntState({
    required this.party,
    required this.board,
    required this.hp,
    required this.damage,
  });

  final Party party;

  /// Members, most damage first.
  final List<PartyStanding> board;
  final int hp;
  final int damage;

  int get hpLeft => math.max(0, hp - damage);
  bool get defeated => party.hasHunt && damage >= hp;
  double get ratioLeft => hp <= 0 ? 0 : hpLeft / hp;

  /// The hunt is over: the boss was beaten, or its last day has passed.
  bool overOn(String day) =>
      party.hasHunt && (defeated || party.end.compareTo(day) < 0);

  static HuntState of({
    required Party party,
    required Map<String, String> members,
    required Map<String, PartyMember> progress,
  }) {
    final board =
        [
          for (final e in members.entries)
            PartyStanding(
              userId: e.key,
              name: e.value,
              member: switch (progress[e.key]) {
                final p? when p.round == party.round => p,
                _ => null,
              },
            ),
        ]..sort((a, b) {
          final c = b.damage.compareTo(a.damage);
          return c != 0 ? c : a.name.compareTo(b.name);
        });
    return HuntState(
      party: party,
      board: board,
      hp: party.hp(members.length),
      damage: board.fold(0, (a, s) => a + s.damage),
    );
  }
}

/// The reward for beating a party's boss: everyone who hit it gets the same.
Reward partyReward({
  required String spaceId,
  required Party party,
  required String day,
}) => pastHuntReward(
  spaceId: spaceId,
  hunt: PastHunt(round: party.round, boss: party.boss, days: party.days),
  day: day,
);

/// The same reward, for a beaten hunt the party has moved on from.
Reward pastHuntReward({
  required String spaceId,
  required PastHunt hunt,
  required String day,
}) => Reward(
  id: 'party-$spaceId-${hunt.round}',
  source: RewardSource.party,
  day: day,
  xp: PartyRules.rewardXp(hunt.days),
  gold: PartyRules.rewardGold(hunt.days),
  title: hunt.boss,
  ref: spaceId,
);
