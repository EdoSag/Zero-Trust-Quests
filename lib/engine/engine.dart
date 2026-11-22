import 'dart:math' as math;

import '../model/days.dart';
import '../model/goal.dart';
import '../model/quest.dart';
import 'catalog.dart';

/// Makes quests and works out difficulty, rewards and progress. Everything
/// here is worked out from the synced goals, quests and purchases alone, so
/// every phone of the account shows the same numbers and nothing has to be
/// kept in step separately.
abstract final class QuestEngine {
  static const minDifficulty = 0.5;
  static const maxDifficulty = 3.0;

  /// Swaps allowed per goal per day after declining.
  static const maxSwaps = 3;

  /// Daily quests completed before a goal offers epic quests.
  static const dailiesBeforeEpics = 3;

  /// A stable hash (FNV-1a), the same on every phone.
  static int hash(String s) {
    var h = 0x811c9dc5;
    for (final c in s.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return h;
  }

  static double roundTo(double v, double step) => step <= 0
      ? v
      : double.parse(((v / step).round() * step).toStringAsFixed(2));

  // ---------------------------------------------------------------- amounts

  /// What [goal] asks of [a] at [difficulty].
  static double amountFor(Activity a, Goal goal, double difficulty) {
    if (a.isCheck) return 1;
    var base = a.base;
    var scale = 1.0;
    for (final o in chosenOptions(goal)) {
      if (o.bases[a.id] case final b?) base = b;
      scale *= o.scale;
    }
    final raw = base * scale * difficulty;
    return roundTo(raw, a.round).clamp(a.min, a.max).toDouble();
  }

  static double customAmount(CustomHabit h, double difficulty) {
    if (h.isCheck) return 1;
    final raw = h.amount * difficulty;
    final step = h.amount >= 10 ? 5.0 : (h.amount >= 3 ? 1.0 : 0.5);
    return math.max(step, roundTo(raw, step));
  }

  static int stepsPerQuest(Goal goal) {
    int? steps;
    for (final o in chosenOptions(goal)) {
      steps = o.steps ?? steps;
    }
    return steps ?? 2;
  }

  static int dailyXp(int steps, double difficulty) =>
      (((10 + 12 * steps) * difficulty.clamp(0.6, 2.5)) / 5).round() * 5;

  static int goldFor(int xp) => math.max(1, xp ~/ 4);

  // ------------------------------------------------------------- difficulty

  /// [goal]'s difficulty for quests of [day], from how earlier quests went.
  /// Starts at 1 (the answers to the set-up questions). Completed quests
  /// raise it 5%, quests left under half done lower it 7%, and declining as
  /// too hard or too easy moves it 15% at once.
  static double difficultyFor(Goal goal, Iterable<Quest> quests, String day) {
    final dailies = [
      for (final q in quests)
        if (q.goalId == goal.id && q.isDaily) q,
    ]..sort(_byDayThenSwap);
    var d = 1.0;
    for (final q in dailies) {
      final past = q.day.compareTo(day) < 0;
      final declinedToday = q.day == day && q.declined != null;
      if (!past && !declinedToday) continue;
      switch (q.declined) {
        case DeclineReason.tooHard:
          d *= 0.85;
        case DeclineReason.tooEasy:
          d *= 1.15;
        case DeclineReason.different || DeclineReason.notToday:
          break;
        case null:
          if (q.stepsDone) {
            d *= 1.05;
          } else if (q.ratio < 0.5) {
            d *= 0.93;
          }
      }
      d = d.clamp(minDifficulty, maxDifficulty);
    }
    return double.parse(d.toStringAsFixed(3));
  }

  static int _byDayThenSwap(Quest a, Quest b) {
    final c = a.day.compareTo(b.day);
    return c != 0 ? c : swapOf(a).compareTo(swapOf(b));
  }

  /// The n in `daily-<goal>-<day>-<n>`.
  static int swapOf(Quest q) => int.tryParse(q.id.split('-').last) ?? 0;

  static String dailyId(String goalId, String day, int swap) =>
      'daily-$goalId-$day-$swap';

  // ------------------------------------------------------------ daily quests

  /// The daily quest of [goal] for [day]: picks [stepsPerQuest] activities
  /// (weighted by the answers, avoiding yesterday's and [avoid]) and sizes
  /// them. The same inputs make the same quest on every phone.
  static Quest daily(
    Goal goal,
    String day, {
    required double difficulty,
    int swap = 0,
    Set<String> avoid = const {},
    Set<String> recent = const {},
  }) {
    final rng = math.Random(hash('${goal.id}|$day|$swap'));
    final count = stepsPerQuest(goal);
    final steps = <QuestStep>[];
    if (goal.category == GoalCategory.custom) {
      final habits = [
        for (final h in goal.habits)
          if (!avoid.contains('custom:${h.label}')) h,
      ];
      final pool = habits.isEmpty ? goal.habits : habits;
      final picked = _pick(rng, {
        for (final h in pool) h.label: 1.0,
      }, math.min(count, pool.length));
      for (final h in pool) {
        if (!picked.contains(h.label)) continue;
        steps.add(
          QuestStep(
            activity: 'custom',
            label: h.label,
            unit: h.unit,
            target: customAmount(h, difficulty),
          ),
        );
      }
    } else {
      final options = chosenOptions(goal);
      final excluded = {for (final o in options) ...o.exclude};
      final weights = <String, double>{};
      for (final a in activities) {
        if (a.category != goal.category || excluded.contains(a.id)) continue;
        var w = 1.0;
        for (final o in options) {
          w *= o.prefer[a.id] ?? 1;
        }
        if (recent.contains(a.id)) w *= 0.5;
        weights[a.id] = w;
      }
      // "Something else": leave out the declined activities while enough
      // others are left.
      if (weights.keys.where((k) => !avoid.contains(k)).length >= count + 1) {
        weights.removeWhere((k, _) => avoid.contains(k));
      }
      // At most one yes/no step, so a quest is never only ticks.
      final picked = <String>[];
      while (picked.length < count && weights.isNotEmpty) {
        final id = _pick(rng, weights, 1).single;
        weights.remove(id);
        final a = activityById[id]!;
        if (a.isCheck && picked.any((p) => activityById[p]!.isCheck)) continue;
        picked.add(id);
      }
      for (final id in picked) {
        final a = activityById[id]!;
        steps.add(
          QuestStep(activity: id, target: amountFor(a, goal, difficulty)),
        );
      }
    }
    final xp = dailyXp(steps.length, difficulty);
    return Quest(
      id: dailyId(goal.id, day, swap),
      goalId: goal.id,
      kind: QuestKind.daily,
      day: day,
      steps: steps,
      difficulty: difficulty,
      xp: xp,
      gold: goldFor(xp),
    );
  }

  /// [n] keys drawn without replacement, weighted.
  static List<String> _pick(
    math.Random rng,
    Map<String, double> weights,
    int n,
  ) {
    final pool = Map.of(weights)..removeWhere((_, w) => w <= 0);
    final out = <String>[];
    // Sorted keys: map order must not change what is drawn.
    while (out.length < n && pool.isNotEmpty) {
      final keys = pool.keys.toList()..sort();
      final total = keys.fold<double>(0, (a, k) => a + pool[k]!);
      var r = rng.nextDouble() * total;
      var chosen = keys.last;
      for (final k in keys) {
        r -= pool[k]!;
        if (r <= 0) {
          chosen = k;
          break;
        }
      }
      out.add(chosen);
      pool.remove(chosen);
    }
    return out;
  }

  /// The daily quests to make for [day]: one per active goal that has none
  /// yet, and a swap for each quest declined for a reason other than
  /// "not today" (up to [maxSwaps] a day).
  static List<Quest> plan(List<Goal> goals, List<Quest> quests, String day) {
    final out = <Quest>[];
    for (final g in goals) {
      if (g.archived || g.createdDay.compareTo(day) > 0) continue;
      if (g.category == GoalCategory.custom && g.habits.isEmpty) continue;
      final todays = [
        for (final q in quests)
          if (q.isDaily && q.goalId == g.id && q.day == day) q,
      ]..sort(_byDayThenSwap);
      final yesterday = {
        for (final q in quests)
          if (q.isDaily && q.goalId == g.id && q.day == addDays(day, -1))
            for (final s in q.steps) s.activity,
      };
      final difficulty = difficultyFor(g, quests, day);
      if (todays.isEmpty) {
        out.add(daily(g, day, difficulty: difficulty, recent: yesterday));
        continue;
      }
      final last = todays.last;
      final reason = last.declined;
      if (reason == null || reason == DeclineReason.notToday) continue;
      final swap = swapOf(last) + 1;
      if (swap > maxSwaps) continue;
      out.add(
        daily(
          g,
          day,
          difficulty: difficulty,
          swap: swap,
          recent: yesterday,
          avoid: reason == DeclineReason.different
              ? {
                  for (final s in last.steps)
                    s.activity == 'custom' ? 'custom:${s.label}' : s.activity,
                }
              : const {},
        ),
      );
    }
    return out;
  }

  /// The quest of [goal] shown for [day]: the newest swap, or null.
  static Quest? currentDaily(String goalId, List<Quest> quests, String day) {
    Quest? best;
    for (final q in quests) {
      if (!q.isDaily || q.goalId != goalId || q.day != day) continue;
      if (best == null || swapOf(q) > swapOf(best)) best = q;
    }
    return best;
  }

  // ------------------------------------------------------------ epic quests

  /// An epic quest [goal] offers on [day], or null: once a few daily quests
  /// are done, when none is running and none was turned down this week.
  static Quest? epicOffer(Goal goal, List<Quest> quests, String day) {
    if (goal.archived) return null;
    final mine = [
      for (final q in quests)
        if (q.goalId == goal.id) q,
    ];
    final doneDailies = mine.where(
      (q) => q.isDaily && q.declined == null && q.stepsDone,
    );
    if (doneDailies.length < dailiesBeforeEpics) return null;
    for (final q in mine) {
      if (q.isDaily) continue;
      if (q.declined != null) {
        if (daysBetween(q.day, day) < 7) return null;
        continue;
      }
      final open = (q.deadline ?? q.day).compareTo(day) >= 0;
      if (open && !epicDone(q, quests)) return null;
      // A short break after finishing one.
      if (daysBetween(q.day, day) < 2) return null;
    }
    final options = chosenOptions(goal);
    final excluded = {for (final o in options) ...o.exclude};
    final templates = [
      for (final t in epicTemplates)
        if (t.category == goal.category &&
            (t.activity == null || !excluded.contains(t.activity)))
          t,
    ];
    if (templates.isEmpty) return null;
    final epicsSoFar = mine.where((q) => !q.isDaily).length;
    final t = templates[hash('${goal.id}|$epicsSoFar') % templates.length];
    final difficulty = difficultyFor(goal, quests, day);
    final QuestStep step;
    if (t.mode == EpicMode.streak) {
      step = QuestStep(activity: 'streak', target: t.count.toDouble());
    } else {
      final a = activityById[t.activity]!;
      final target = math.max(
        t.minimum,
        roundTo(amountFor(a, goal, difficulty) * t.factor, a.round),
      );
      step = QuestStep(activity: a.id, target: target);
    }
    final xp =
        ((100 + 12 * t.days) * difficulty.clamp(0.6, 2.5) / 10).round() * 10;
    return Quest(
      id: 'epic-${goal.id}-$day',
      goalId: goal.id,
      kind: QuestKind.epic,
      day: day,
      deadline: addDays(day, t.days - 1),
      steps: [step],
      difficulty: difficulty,
      xp: xp,
      gold: math.max(10, xp ~/ 3),
      mode: t.mode,
      template: t.id,
    );
  }

  /// An epic quest the user wrote: one step, by hand or from the dailies.
  static Quest ownEpic({
    required String id,
    required Goal goal,
    required String title,
    required double target,
    required String unit,
    required String day,
    required int days,
  }) {
    final xp = (math.min(600, 80 + 10 * days) / 10).round() * 10;
    return Quest(
      id: id,
      goalId: goal.id,
      kind: QuestKind.epic,
      day: day,
      deadline: addDays(day, days - 1),
      steps: [
        QuestStep(activity: 'custom', label: title, unit: unit, target: target),
      ],
      difficulty: 1,
      xp: xp,
      gold: math.max(10, xp ~/ 3),
      title: title,
      mode: EpicMode.total,
    );
  }

  /// [epic]'s steps with their real progress: what was logged by hand, plus
  /// the goal's daily quests and Health Connect days inside its window. An
  /// epic without a goal (a seasonal event) counts every goal's dailies.
  static List<QuestStep> epicSteps(Quest epic, Iterable<Quest> quests) {
    final end = epic.deadline ?? epic.day;
    bool inWindow(String d) =>
        d.compareTo(epic.day) >= 0 && d.compareTo(end) <= 0;
    final anyGoal = epic.goalId.isEmpty;
    final dailies = [
      for (final q in quests)
        if (q.isDaily &&
            (anyGoal || q.goalId == epic.goalId) &&
            q.declined == null &&
            inWindow(q.day))
          q,
    ];
    return [
      for (final s in epic.steps)
        switch (epic.mode) {
          EpicMode.streak => s.withProgress(
            {
              for (final q in dailies)
                if (q.stepsDone) q.day,
            }.length.toDouble(),
          ),
          EpicMode.total => s.withProgress(
            s.progress +
                _sumByDay(s, dailies).values.fold(0.0, (a, v) => a + v),
          ),
          EpicMode.best => s.withProgress(
            _sumByDay(s, dailies).values.fold(s.progress, math.max),
          ),
        },
    ];
  }

  /// Per day: the larger of the daily quests' progress on [s]'s activity
  /// and Health Connect's value.
  static Map<String, double> _sumByDay(QuestStep s, List<Quest> dailies) {
    final out = <String, double>{...s.byDay};
    if (s.activity == 'custom') return out;
    final fromQuests = <String, double>{};
    for (final q in dailies) {
      for (final d in q.steps) {
        if (d.activity == s.activity) {
          fromQuests[q.day] = math.max(fromQuests[q.day] ?? 0, d.progress);
        }
      }
    }
    for (final e in fromQuests.entries) {
      out[e.key] = math.max(out[e.key] ?? 0, e.value);
    }
    return out;
  }

  static bool epicDone(Quest epic, Iterable<Quest> quests) {
    final steps = epicSteps(epic, quests);
    return steps.isNotEmpty && steps.every((s) => s.done);
  }

  /// Whether [q] earned its reward.
  static bool completed(Quest q, Iterable<Quest> quests) =>
      q.declined == null && (q.isDaily ? q.stepsDone : epicDone(q, quests));
}
