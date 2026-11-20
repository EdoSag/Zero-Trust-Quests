import 'package:flutter_test/flutter_test.dart';
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
}
