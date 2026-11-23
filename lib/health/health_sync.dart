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
            final v = metric == null ? null : health[metric];
            if (q.isDaily) {
              var next = s;
              // A run logged without a distance finishes the day's run,
              // without adding kilometres (which would reach epics).
              final finishedBy = activity?.finishedBy;
              if (finishedBy != null &&
                  (health[finishedBy] ?? 0) > 0 &&
                  !next.finished) {
                next = next.asFinished();
              }
              if (v != null && v > next.progress) next = next.withProgress(v);
              if (next == s) return s;
              changed = true;
              return next;
            }
            if (v == null) return s;
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
