import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:zerotrust_quests/engine/catalog.dart';
import 'package:zerotrust_quests/engine/engine.dart';
import 'package:zerotrust_quests/health/health_source.dart';
import 'package:zerotrust_quests/health/health_sync.dart';
import 'package:zerotrust_quests/model/quest.dart';

const day = '2026-11-20';

Quest waterQuest({double target = 6, double progress = 0}) => Quest(
  id: 'daily-g1-$day-0',
  goalId: 'g1',
  kind: QuestKind.daily,
  day: day,
  steps: [
    QuestStep(activity: 'water', target: target, progress: progress),
    const QuestStep(activity: 'veggies', target: 3),
  ],
  difficulty: 1,
  xp: 10,
  gold: 5,
);

HealthDay water(double liters) =>
    HealthDay({HealthMetric.waterGlasses: glassesFromLiters(liters)});

void main() {
  group('glasses of water', () {
    test('each 250 ml glass logged in ZT Fitness is one glass', () {
      for (var n = 0; n <= 12; n++) {
        expect(glassesFromLiters(n * 0.25), n, reason: '$n glasses');
      }
      expect(glassesFromLiters(0.5), 2);
      expect(glassesFromLiters(0.75), 3);
    });

    test('each 8 oz glass logged in ZT Fitness is one glass', () {
      // ZT Fitness's own (rounded) litres per fluid ounce.
      const fitnessLitersPerFlOz = 0.0295735;
      for (var n = 0; n <= 12; n++) {
        expect(
          glassesFromLiters(n * 8 * fitnessLitersPerFlOz),
          n,
          reason: '$n glasses',
        );
      }
      expect(glassesFromLiters(16 * fitnessLitersPerFlOz), 2);
      expect(glassesFromLiters(24 * fitnessLitersPerFlOz), 3);
    });

    test('a few sips are not a glass', () {
      expect(glassesFromLiters(0), 0);
      expect(glassesFromLiters(-1), 0);
      expect(glassesFromLiters(0.1), 0);
      expect(glassesFromLiters(0.2), 0);
      expect(glassesFromLiters(0.45), 1);
    });
  });

  group('water from ZT Fitness', () {
    test('adds progress to the day\'s water quest', () {
      final changed = HealthFill.apply([waterQuest()], day, water(0.75));
      expect(changed, hasLength(1));
      expect(changed.single.steps[0].progress, 3);
      expect(changed.single.steps[1].progress, 0, reason: 'only water moves');
    });

    test('finishes the step once enough was drunk', () {
      final changed = HealthFill.apply([waterQuest()], day, water(1.5));
      expect(changed.single.steps[0].done, isTrue);
    });

    test('never lowers glasses ticked by hand, and saves nothing new', () {
      final q = waterQuest(progress: 4);
      expect(HealthFill.apply([q], day, water(0.5)), isEmpty);
      expect(HealthFill.apply([q], day, water(1.0)), isEmpty);
      expect(
        HealthFill.apply([q], day, water(1.25)).single.steps[0].progress,
        5,
      );
    });

    test('leaves other days and declined quests alone', () {
      expect(
        HealthFill.apply([waterQuest()], '2026-11-21', water(1.0)),
        isEmpty,
      );
      final declined = waterQuest().copyWith(declined: DeclineReason.notToday);
      expect(HealthFill.apply([declined], day, water(1.0)), isEmpty);
    });

    test('counts each day toward an epic water quest', () {
      const epic = Quest(
        id: 'epic-1',
        goalId: 'g1',
        kind: QuestKind.epic,
        day: '2026-11-19',
        deadline: '2026-11-25',
        steps: [QuestStep(activity: 'water', target: 20)],
        difficulty: 1,
        xp: 50,
        gold: 20,
      );
      var q = HealthFill.apply([epic], '2026-11-19', water(1.5)).single;
      q = HealthFill.apply([q], day, water(1.0)).single;
      // The same reading again changes nothing.
      expect(HealthFill.apply([q], day, water(1.0)), isEmpty);
      expect(QuestEngine.epicSteps(q, const []).single.progress, 10);
    });
  });

  group('workouts from ZT Fitness', () {
    final dayStart = DateTime(2026, 11, 20);
    final dayEnd = DateTime(2026, 11, 21);
    DateTime at(int h, [int m = 0]) => DateTime(2026, 11, 20, h, m);
    WorkoutSession session(
      HealthWorkoutActivityType type,
      DateTime from,
      int minutes, {
      double? meters,
    }) => WorkoutSession(
      type,
      from,
      from.add(Duration(minutes: minutes)),
      meters: meters,
    );
    Map<HealthMetric, double> values(List<WorkoutSession> s) =>
        workoutValues(s, dayStart, dayEnd);

    Quest daily(List<QuestStep> steps) => Quest(
      id: 'daily-g1-$day-0',
      goalId: 'g1',
      kind: QuestKind.daily,
      day: day,
      steps: steps,
      difficulty: 1,
      xp: 10,
      gold: 5,
    );

    test('any workout fills workout minutes', () {
      final v = values([
        session(HealthWorkoutActivityType.STRENGTH_TRAINING, at(7), 25),
        session(HealthWorkoutActivityType.BIKING, at(18), 20),
      ]);
      expect(v[HealthMetric.workoutMinutes], 45);
      final q = daily([const QuestStep(activity: 'workout', target: 30)]);
      final changed = HealthFill.apply([q], day, HealthDay(v));
      expect(changed.single.steps.single.progress, 45);
      expect(changed.single.steps.single.done, isTrue);
    });

    test('the same workout from ZT Fitness and a watch counts once', () {
      final v = values([
        session(HealthWorkoutActivityType.RUNNING, at(7), 30, meters: 5000),
        session(HealthWorkoutActivityType.RUNNING, at(7, 2), 30, meters: 5100),
      ]);
      expect(v[HealthMetric.workoutMinutes], 32);
      expect(v[HealthMetric.runKm], 5.1, reason: 'the longer distance');
      expect(v[HealthMetric.runsWithoutDistance], isNull);
    });

    test('runs fill the run step with their distance', () {
      final v = values([
        session(HealthWorkoutActivityType.RUNNING, at(7), 20, meters: 2500),
        session(
          HealthWorkoutActivityType.RUNNING_TREADMILL,
          at(19),
          10,
          meters: 1000,
        ),
      ]);
      expect(v[HealthMetric.runKm], 3.5);
      final q = daily([const QuestStep(activity: 'run', target: 3)]);
      expect(
        HealthFill.apply([q], day, HealthDay(v)).single.steps.single.done,
        isTrue,
      );
    });

    test('walks and rides are not runs', () {
      final v = values([
        session(HealthWorkoutActivityType.WALKING, at(7), 60, meters: 5000),
        session(HealthWorkoutActivityType.BIKING, at(9), 60, meters: 20000),
      ]);
      expect(v[HealthMetric.runKm], isNull);
      expect(v[HealthMetric.runsWithoutDistance], isNull);
      final q = daily([const QuestStep(activity: 'run', target: 2)]);
      expect(HealthFill.apply([q], day, HealthDay(v)), isEmpty);
    });

    test('a run logged without a distance finishes the day\'s run', () {
      final v = values([session(HealthWorkoutActivityType.RUNNING, at(7), 30)]);
      expect(v[HealthMetric.runsWithoutDistance], 1);
      final q = daily([
        const QuestStep(activity: 'run', target: 4),
        const QuestStep(activity: 'pushups', target: 20),
      ]);
      final changed = HealthFill.apply([q], day, HealthDay(v)).single;
      expect(changed.steps[0].done, isTrue);
      expect(changed.steps[1].progress, 0);
    });

    test('but only a distance counts toward an epic run', () {
      const epic = Quest(
        id: 'epic-run',
        goalId: 'g1',
        kind: QuestKind.epic,
        day: day,
        deadline: '2026-12-01',
        mode: EpicMode.best,
        steps: [QuestStep(activity: 'run', target: 5)],
        difficulty: 1,
        xp: 50,
        gold: 20,
      );
      final v = values([session(HealthWorkoutActivityType.RUNNING, at(7), 30)]);
      expect(HealthFill.apply([epic], day, HealthDay(v)), isEmpty);
    });

    test('yoga fills stretching and walks fill walking outside', () {
      final v = values([
        session(HealthWorkoutActivityType.YOGA, at(6), 15),
        session(HealthWorkoutActivityType.WALKING, at(12), 25),
        session(HealthWorkoutActivityType.HIKING, at(15), 40),
      ]);
      expect(v[HealthMetric.stretchMinutes], 15);
      expect(v[HealthMetric.walkMinutes], 65);
      expect(v[HealthMetric.workoutMinutes], 80);
      final q = daily([
        const QuestStep(activity: 'stretch', target: 10),
        const QuestStep(activity: 'walkOutside', target: 20),
      ]);
      final changed = HealthFill.apply([q], day, HealthDay(v)).single;
      expect(changed.steps.every((s) => s.done), isTrue);
    });

    test('only the part of a workout inside the day counts', () {
      final v = values([
        session(
          HealthWorkoutActivityType.RUNNING,
          DateTime(2026, 11, 19, 23, 40),
          40,
          meters: 6000,
        ),
      ]);
      expect(v[HealthMetric.workoutMinutes], 20);
      expect(
        v[HealthMetric.runKm],
        isNull,
        reason: 'the run belongs to the day it started',
      );
    });

    test('never lowers minutes logged by hand', () {
      final q = daily([
        const QuestStep(activity: 'workout', target: 30, progress: 25),
      ]);
      final v = values([session(HealthWorkoutActivityType.OTHER, at(7), 20)]);
      expect(HealthFill.apply([q], day, HealthDay(v)), isEmpty);
    });
  });
}
