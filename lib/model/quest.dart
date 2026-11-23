import 'package:flutter/foundation.dart';

/// Daily quests reset every day; epic quests are bigger, one-time goals
/// with a deadline.
enum QuestKind {
  daily,
  epic;

  static QuestKind parse(Object? v) =>
      v == 'epic' ? QuestKind.epic : QuestKind.daily;
}

/// Why a quest was declined. Too hard and too easy move the goal's
/// difficulty at once; "something else" swaps the activities; "not today"
/// skips the goal for the day.
enum DeclineReason {
  tooHard,
  tooEasy,
  different,
  notToday;

  static DeclineReason? parse(Object? v) {
    for (final r in DeclineReason.values) {
      if (r.name == v) return r;
    }
    return null;
  }
}

/// How an epic counts its steps: the best single day, the total over the
/// window, or days on which a daily quest of the goal was completed.
enum EpicMode {
  best,
  total,
  streak;

  static EpicMode parse(Object? v) => EpicMode.values.firstWhere(
    (m) => m.name == v,
    orElse: () => EpicMode.total,
  );
}

/// One part of a quest: "25 push-ups". [activity] is a catalog id, or
/// `custom` with the user's own [label] and [unit].
@immutable
class QuestStep {
  const QuestStep({
    required this.activity,
    required this.target,
    this.progress = 0,
    this.label = '',
    this.unit = '',
    this.byDay = const {},
    this.finished = false,
  });

  final String activity;
  final double target;

  /// Logged by hand. For an epic, what was logged on top of the daily
  /// quests.
  final double progress;
  final String label;
  final String unit;

  /// Epic only: Health Connect's value for each day (`yyyy-MM-dd`).
  final Map<String, double> byDay;

  /// Daily only: finished without an amount, by a run logged in ZT Fitness
  /// without a distance. Kept apart from [progress] so it never adds
  /// kilometres to an epic.
  final bool finished;

  bool get done => finished || progress >= target;
  double get ratio =>
      finished || target <= 0 ? 1 : (progress / target).clamp(0, 1);

  QuestStep withProgress(double p) => QuestStep(
    activity: activity,
    target: target,
    progress: p < 0 ? 0 : p,
    label: label,
    unit: unit,
    byDay: byDay,
    finished: finished,
  );

  QuestStep withDay(String day, double value) => QuestStep(
    activity: activity,
    target: target,
    progress: progress,
    label: label,
    unit: unit,
    byDay: {...byDay, day: value},
    finished: finished,
  );

  QuestStep asFinished() => QuestStep(
    activity: activity,
    target: target,
    progress: progress,
    label: label,
    unit: unit,
    byDay: byDay,
    finished: true,
  );

  Map<String, Object?> toJson() => {
    'activity': activity,
    'target': target,
    'progress': progress,
    if (label.isNotEmpty) 'label': label,
    if (unit.isNotEmpty) 'unit': unit,
    if (byDay.isNotEmpty) 'byDay': byDay,
    if (finished) 'finished': true,
  };

  static QuestStep fromJson(Map<String, Object?> j) => QuestStep(
    activity: (j['activity'] as String?) ?? 'custom',
    target: (j['target'] as num?)?.toDouble() ?? 1,
    progress: (j['progress'] as num?)?.toDouble() ?? 0,
    label: (j['label'] as String?) ?? '',
    unit: (j['unit'] as String?) ?? '',
    byDay: {
      for (final e in ((j['byDay'] as Map?) ?? const {}).entries)
        if (e.value is num) '${e.key}': (e.value as num).toDouble(),
    },
    finished: j['finished'] == true,
  );

  @override
  bool operator ==(Object other) =>
      other is QuestStep &&
      mapEquals(other.byDay, byDay) &&
      other.activity == activity &&
      other.target == target &&
      other.progress == progress &&
      other.label == label &&
      other.unit == unit &&
      other.finished == finished;

  @override
  int get hashCode => Object.hash(
    activity,
    target,
    progress,
    label,
    unit,
    byDay.length,
    finished,
  );
}

/// A quest. Daily quests have the id `daily-<goal>-<day>-<n>` (n counts
/// swaps after a decline), so two phones make the same one.
@immutable
class Quest {
  const Quest({
    required this.id,
    required this.goalId,
    required this.kind,
    required this.day,
    this.deadline,
    required this.steps,
    required this.difficulty,
    required this.xp,
    required this.gold,
    this.title = '',
    this.mode = EpicMode.total,
    this.template = '',
    this.declined,
    this.declineCost = 0,
    this.claimed = false,
  });

  final String id;
  final String goalId;
  final QuestKind kind;

  /// Daily: the day it is for. Epic: the day it was accepted.
  final String day;

  /// Epic: the last day it can be completed.
  final String? deadline;
  final List<QuestStep> steps;

  /// The goal's difficulty when the quest was made (1.0 = as answered).
  final double difficulty;
  final int xp;
  final int gold;

  /// Epic quests the user made themselves have a title.
  final String title;
  final EpicMode mode;

  /// Epic: the catalog template it came from (empty for the user's own).
  final String template;
  final DeclineReason? declined;

  /// Gold paid to decline (after the free decline of the day).
  final int declineCost;

  /// The reward was celebrated on some device. Rewards count from the steps
  /// either way; this only stops the celebration showing twice.
  final bool claimed;

  bool get isDaily => kind == QuestKind.daily;
  bool get stepsDone => steps.isNotEmpty && steps.every((s) => s.done);
  double get ratio => steps.isEmpty
      ? 0
      : steps.fold<double>(0, (a, s) => a + s.ratio) / steps.length;

  Quest copyWith({
    List<QuestStep>? steps,
    DeclineReason? declined,
    int? declineCost,
    bool? claimed,
  }) => Quest(
    id: id,
    goalId: goalId,
    kind: kind,
    day: day,
    deadline: deadline,
    steps: steps ?? this.steps,
    difficulty: difficulty,
    xp: xp,
    gold: gold,
    title: title,
    mode: mode,
    template: template,
    declined: declined ?? this.declined,
    declineCost: declineCost ?? this.declineCost,
    claimed: claimed ?? this.claimed,
  );

  Map<String, Object?> toJson() => {
    'goalId': goalId,
    'questKind': kind.name,
    'day': day,
    if (deadline != null) 'deadline': deadline,
    'steps': [for (final s in steps) s.toJson()],
    'difficulty': difficulty,
    'xp': xp,
    'gold': gold,
    if (title.isNotEmpty) 'title': title,
    'mode': mode.name,
    if (template.isNotEmpty) 'template': template,
    'declined': declined?.name,
    'declineCost': declineCost,
    'claimed': claimed,
  };

  static Quest fromJson(String id, Map<String, Object?> j) => Quest(
    id: id,
    goalId: (j['goalId'] as String?) ?? '',
    kind: QuestKind.parse(j['questKind']),
    day: (j['day'] as String?) ?? '2026-01-01',
    deadline: j['deadline'] as String?,
    steps: [
      for (final s in (j['steps'] as List?) ?? const [])
        if (s is Map) QuestStep.fromJson(s.cast<String, Object?>()),
    ],
    difficulty: (j['difficulty'] as num?)?.toDouble() ?? 1,
    xp: (j['xp'] as num?)?.toInt() ?? 0,
    gold: (j['gold'] as num?)?.toInt() ?? 0,
    title: (j['title'] as String?) ?? '',
    mode: EpicMode.parse(j['mode']),
    template: (j['template'] as String?) ?? '',
    declined: DeclineReason.parse(j['declined']),
    declineCost: (j['declineCost'] as num?)?.toInt() ?? 0,
    claimed: j['claimed'] == true,
  );
}

/// Something bought with gold. Kept as its own item so purchases on two
/// phones never overwrite each other.
@immutable
class Purchase {
  const Purchase({
    required this.id,
    required this.item,
    required this.cost,
    required this.day,
  });

  final String id;

  /// A shop item id: `freeze`, `emblem:<id>`, `color:<id>`.
  final String item;
  final int cost;
  final String day;

  Map<String, Object?> toJson() => {'item': item, 'cost': cost, 'day': day};

  static Purchase fromJson(String id, Map<String, Object?> j) => Purchase(
    id: id,
    item: (j['item'] as String?) ?? '',
    cost: (j['cost'] as num?)?.toInt() ?? 0,
    day: (j['day'] as String?) ?? '2026-01-01',
  );
}

/// The user's hero: name and the look they picked.
@immutable
class HeroLook {
  const HeroLook({this.name = '', this.emblem = 'shield', this.color = 'teal'});

  final String name;
  final String emblem;
  final String color;

  HeroLook copyWith({String? name, String? emblem, String? color}) => HeroLook(
    name: name ?? this.name,
    emblem: emblem ?? this.emblem,
    color: color ?? this.color,
  );

  Map<String, Object?> toJson() => {
    'name': name,
    'emblem': emblem,
    'color': color,
  };

  static HeroLook fromJson(Map<String, Object?> j) => HeroLook(
    name: (j['name'] as String?) ?? '',
    emblem: (j['emblem'] as String?) ?? 'shield',
    color: (j['color'] as String?) ?? 'teal',
  );
}
