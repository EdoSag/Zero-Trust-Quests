import '../engine/catalog.dart';
import '../model/days.dart';
import '../model/quest.dart';
import 'health_source.dart';

/// Fills quest steps from Health Connect. Never lowers what was logged by
/// hand: a daily step takes the larger value; an epic keeps each day's
/// value beside what was logged.
///
/// Workouts logged in ZT Fitness reach here through Health Connect: their
/// minutes fill workout steps, runs fill run steps, yoga fills stretching
/// and walks fill walking outside (see [workoutValues]).
abstract final class HealthFill {
  /// Quests changed by [day]'s values, ready to save.
  static List<Quest> apply(List<Quest> quests, String day, HealthDay health) {
    final out = <Quest>[];
    for (final q in quests) {
      if (q.declined != null) continue;
      final active = q.isDaily
          ? q.day == day
          : q.day.compareTo(day) <= 0 &&
                (q.deadline ?? q.day).compareTo(day) >= 0;
      if (!active) continue;
      var changed = false;
      final steps = [
        for (final s in q.steps)
          () {
            final activity = activityById[s.activity];
            final metric = activity?.health;
            var v = metric == null ? null : health[metric];
            // A run logged without a distance finishes the day's run.
            final finishedBy = activity?.finishedBy;
            if (q.isDaily &&
                finishedBy != null &&
                (health[finishedBy] ?? 0) > 0 &&
                (v ?? 0) < s.target) {
              v = s.target;
            }
            if (v == null) return s;
            if (q.isDaily) {
              if (v <= s.progress) return s;
              changed = true;
              return s.withProgress(v);
            }
            if ((s.byDay[day] ?? -1) == v) return s;
            changed = true;
            return s.withDay(day, v);
          }(),
      ];
      if (changed) out.add(q.copyWith(steps: steps));
    }
    return out;
  }

  /// Days to read: today, plus yesterday until noon (late syncs).
  static List<String> daysToRead(DateTime now) => [
    dayKey(now),
    if (now.hour < 12) dayKey(now.subtract(const Duration(days: 1))),
  ];
}
