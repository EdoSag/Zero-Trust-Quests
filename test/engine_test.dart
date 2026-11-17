import 'package:flutter_test/flutter_test.dart';
import 'package:zerotrust_quests/engine/catalog.dart';
import 'package:zerotrust_quests/engine/engine.dart';
import 'package:zerotrust_quests/engine/hero.dart';
import 'package:zerotrust_quests/model/days.dart';
import 'package:zerotrust_quests/model/goal.dart';
import 'package:zerotrust_quests/model/quest.dart';

const fit = Goal(
  id: 'g1',
  category: GoalCategory.fitness,
  answers: {'level': 'some', 'time': 'min40'},
  createdDay: '2026-11-01',
);

Quest done(Quest q) =>
    q.copyWith(steps: [for (final s in q.steps) s.withProgress(s.target)]);

void main() {
  group('daily quests', () {
    test('same goal and day make the same quest on every phone', () {
      final a = QuestEngine.daily(fit, '2026-11-17', difficulty: 1);
      final b = QuestEngine.daily(fit, '2026-11-17', difficulty: 1);
      expect(a.toJson(), b.toJson());
      expect(a.id, 'daily-g1-2026-11-17-0');
      expect(a.steps, hasLength(3)); // 40 minutes a day
      expect(a.steps.map((s) => s.activity).toSet(), hasLength(3));
      for (final s in a.steps) {
        expect(activityById[s.activity]!.category, GoalCategory.fitness);
      }
    });

    test('answers size the steps', () {
      final weak = fit.copyWith(
        answers: {'pushups': 'p0', 'level': 'beginner'},
      );
      final strong = fit.copyWith(
        answers: {'pushups': 'p40', 'level': 'experienced'},
      );
      final a = activityById['pushups']!;
      expect(QuestEngine.amountFor(a, weak, 1), 3);
      expect(QuestEngine.amountFor(a, strong, 1), 30);
      expect(QuestEngine.amountFor(a, strong, 2), 60);
    });

    test('a quest never has two yes/no steps', () {
      const prod = Goal(
        id: 'p',
        category: GoalCategory.productivity,
        answers: {'time': 'min60'},
        createdDay: '2026-11-01',
      );
      for (var i = 0; i < 60; i++) {
        final q = QuestEngine.daily(
          prod,
          addDays('2026-11-01', i),
          difficulty: 1,
        );
        final checks = q.steps.where((s) => activityById[s.activity]!.isCheck);
        expect(checks.length, lessThanOrEqualTo(1));
      }
    });

    test('custom goals use their own habits', () {
      const guitar = Goal(
        id: 'c',
        category: GoalCategory.custom,
        name: 'Music',
        habits: [
          CustomHabit(label: 'Practise guitar', amount: 20, unit: 'min'),
          CustomHabit(label: 'Learn a song'),
        ],
        answers: {'time': 'min40'},
        createdDay: '2026-11-01',
      );
      final q = QuestEngine.daily(guitar, '2026-11-17', difficulty: 1.5);
      expect(q.steps.map((s) => s.label), ['Practise guitar', 'Learn a song']);
      expect(q.steps.first.target, 30);
      expect(q.steps.last.target, 1);
    });

    test('plan makes one quest per active goal, and swaps after a decline', () {
      final day = '2026-11-17';
      var quests = QuestEngine.plan([fit], const [], day);
      expect(quests, hasLength(1));
      expect(QuestEngine.plan([fit], quests, day), isEmpty);

      final first = quests.single;
      quests = [first.copyWith(declined: DeclineReason.different)];
      final swap = QuestEngine.plan([fit], quests, day).single;
      expect(swap.id, 'daily-g1-2026-11-17-1');
      expect(
        swap.steps
            .map((s) => s.activity)
            .toSet()
            .intersection(first.steps.map((s) => s.activity).toSet()),
        isEmpty,
      );

      // Not today: nothing new.
      quests = [first.copyWith(declined: DeclineReason.notToday)];
      expect(QuestEngine.plan([fit], quests, day), isEmpty);
      // Archived goals and goals set later get nothing.
      expect(
        QuestEngine.plan([fit.copyWith(archived: true)], const [], day),
        isEmpty,
      );
      expect(QuestEngine.plan([fit], const [], '2026-10-01'), isEmpty);
    });
  });

  group('difficulty', () {
    test('rises with completed quests and falls with missed ones', () {
      final quests = <Quest>[];
      for (var i = 0; i < 5; i++) {
        quests.add(
          done(QuestEngine.daily(fit, addDays('2026-11-01', i), difficulty: 1)),
        );
      }
      final up = QuestEngine.difficultyFor(fit, quests, '2026-11-06');
      expect(up, closeTo(1.276, 0.001)); // 1.05^5

      final missed = [
        for (var i = 0; i < 5; i++)
          QuestEngine.daily(fit, addDays('2026-11-01', i), difficulty: 1),
      ];
      expect(
        QuestEngine.difficultyFor(fit, missed, '2026-11-06'),
        lessThan(0.7),
      );
    });

    test('too hard / too easy act on the same day', () {
      final q = QuestEngine.daily(fit, '2026-11-17', difficulty: 1);
      expect(
        QuestEngine.difficultyFor(fit, [
          q.copyWith(declined: DeclineReason.tooHard),
        ], '2026-11-17'),
        0.85,
      );
      final easier = QuestEngine.plan(
        [fit],
        [q.copyWith(declined: DeclineReason.tooHard)],
        '2026-11-17',
      ).single;
      expect(easier.difficulty, 0.85);
      expect(
        QuestEngine.difficultyFor(fit, [
          q.copyWith(declined: DeclineReason.tooEasy),
        ], '2026-11-17'),
        1.15,
      );
    });

    test('stays between 0.5 and 3', () {
      final quests = [
        for (var i = 0; i < 60; i++)
          done(QuestEngine.daily(fit, addDays('2026-09-01', i), difficulty: 1)),
      ];
      expect(QuestEngine.difficultyFor(fit, quests, '2026-12-01'), 3);
    });
  });

  group('epic quests', () {
    test('offered after three completed dailies, counted from the dailies', () {
      final quests = [
        for (var i = 0; i < 2; i++)
          done(QuestEngine.daily(fit, addDays('2026-11-01', i), difficulty: 1)),
      ];
      expect(QuestEngine.epicOffer(fit, quests, '2026-11-03'), isNull);
      quests.add(done(QuestEngine.daily(fit, '2026-11-03', difficulty: 1)));
      final offer = QuestEngine.epicOffer(fit, quests, '2026-11-04');
      expect(offer, isNotNull);
      expect(offer!.kind, QuestKind.epic);
      expect(offer.deadline!.compareTo(offer.day), greaterThan(0));

      // While one runs, no other is offered.
      expect(
        QuestEngine.epicOffer(fit, [...quests, offer], '2026-11-05'),
        isNull,
      );
      // Turned down: not again for a week.
      final no = offer.copyWith(declined: DeclineReason.notToday);
      expect(QuestEngine.epicOffer(fit, [...quests, no], '2026-11-08'), isNull);
      expect(
        QuestEngine.epicOffer(fit, [...quests, no], '2026-11-11'),
        isNotNull,
      );
    });

    test('streak epics count days with a completed daily', () {
      const epic = Quest(
        id: 'e',
        goalId: 'g1',
        kind: QuestKind.epic,
        day: '2026-11-01',
        deadline: '2026-11-10',
        steps: [QuestStep(activity: 'streak', target: 3)],
        difficulty: 1,
        xp: 200,
        gold: 60,
        mode: EpicMode.streak,
      );
      final quests = <Quest>[
        epic,
        done(QuestEngine.daily(fit, '2026-10-31', difficulty: 1)), // before
        done(QuestEngine.daily(fit, '2026-11-02', difficulty: 1)),
        done(QuestEngine.daily(fit, '2026-11-05', difficulty: 1)),
      ];
      expect(QuestEngine.epicSteps(epic, quests).single.progress, 2);
      expect(QuestEngine.epicDone(epic, quests), isFalse);
      quests.add(done(QuestEngine.daily(fit, '2026-11-09', difficulty: 1)));
      expect(QuestEngine.epicDone(epic, quests), isTrue);
    });

    test(
      'total and best epics add dailies, Health Connect days and own logs',
      () {
        final total = Quest(
          id: 'e',
          goalId: 'g1',
          kind: QuestKind.epic,
          day: '2026-11-01',
          deadline: '2026-11-14',
          steps: [
            const QuestStep(
              activity: 'run',
              target: 10,
              progress: 1,
            ).withDay('2026-11-03', 4),
          ],
          difficulty: 1,
          xp: 200,
          gold: 60,
        );
        const daily = Quest(
          id: 'daily-g1-2026-11-03-0',
          goalId: 'g1',
          kind: QuestKind.daily,
          day: '2026-11-03',
          steps: [QuestStep(activity: 'run', target: 2, progress: 3)],
          difficulty: 1,
          xp: 30,
          gold: 7,
        );
        const daily2 = Quest(
          id: 'daily-g1-2026-11-04-0',
          goalId: 'g1',
          kind: QuestKind.daily,
          day: '2026-11-04',
          steps: [QuestStep(activity: 'run', target: 2, progress: 2.5)],
          difficulty: 1,
          xp: 30,
          gold: 7,
        );
        // Nov 3: max(health 4, logged 3) = 4; Nov 4: 2.5; plus 1 by hand.
        expect(
          QuestEngine.epicSteps(total, [daily, daily2]).single.progress,
          7.5,
        );
        final best = total.copyWith();
        final bestEpic = Quest.fromJson(best.id, {
          ...best.toJson(),
          'mode': 'best',
        });
        expect(
          QuestEngine.epicSteps(bestEpic, [daily, daily2]).single.progress,
          4,
        );
      },
    );
  });

  group('hero', () {
    test('levels', () {
      expect(Levels.levelFor(0), 1);
      expect(Levels.levelFor(99), 1);
      expect(Levels.levelFor(100), 2);
      expect(Levels.levelFor(299), 2);
      expect(Levels.levelFor(300), 3);
      expect(Levels.levelFor(4500), 10);
      expect(Levels.titleFor(1), 'novice');
      expect(Levels.titleFor(12), 'pathfinder');
      expect(Levels.titleFor(60), 'legend');
    });

    test('XP, gold, streak bonus, declines and purchases', () {
      final d1 = done(QuestEngine.daily(fit, '2026-11-15', difficulty: 1));
      final d2 = done(QuestEngine.daily(fit, '2026-11-16', difficulty: 1));
      final d3 = QuestEngine.daily(
        fit,
        '2026-11-17',
        difficulty: 1,
      ).copyWith(declined: DeclineReason.notToday);
      final stats = HeroStats.compute(
        [d1, d2, d3],
        const [
          Purchase(id: 'p', item: 'emblem:star', cost: 15, day: '2026-11-16'),
        ],
        '2026-11-17',
      );
      // Day 2 earns a 5% streak bonus.
      expect(stats.xp, d1.xp + d2.xp + (d2.xp * 0.05).floor());
      expect(stats.gold, d1.gold + d2.gold - 15);
      expect(stats.streak, 2);
      expect(stats.freeDeclineLeft, isFalse);
      expect(stats.owned, {'emblem:star'});
    });

    test('a streak freeze bridges one missed day', () {
      final quests = [
        done(QuestEngine.daily(fit, '2026-11-10', difficulty: 1)),
        done(QuestEngine.daily(fit, '2026-11-11', difficulty: 1)),
        // 12th missed
        done(QuestEngine.daily(fit, '2026-11-13', difficulty: 1)),
      ];
      expect(HeroStats.compute(quests, const [], '2026-11-13').streak, 1);
      final withFreeze = HeroStats.compute(quests, const [
        Purchase(id: 'f', item: Shop.freeze, cost: 60, day: '2026-11-11'),
      ], '2026-11-13');
      expect(withFreeze.streak, 3);
      expect(withFreeze.freezes, 0);
      expect(withFreeze.bestStreak, 3);
    });

    test('today not done yet keeps the streak', () {
      final quests = [
        done(QuestEngine.daily(fit, '2026-11-16', difficulty: 1)),
        QuestEngine.daily(fit, '2026-11-17', difficulty: 1),
      ];
      expect(HeroStats.compute(quests, const [], '2026-11-17').streak, 1);
      expect(HeroStats.compute(quests, const [], '2026-11-18').streak, 0);
    });
  });

  test('items survive a JSON round trip', () {
    final q = QuestEngine.daily(
      fit,
      '2026-11-17',
      difficulty: 1.2,
    ).copyWith(declined: DeclineReason.tooEasy, declineCost: 10);
    expect(Quest.fromJson(q.id, q.toJson()).toJson(), q.toJson());
    expect(Goal.fromJson('g1', fit.toJson()).toJson(), fit.toJson());
  });
}
