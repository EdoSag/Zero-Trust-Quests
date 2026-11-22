import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zerotrust_quests/engine/achievements.dart';
import 'package:zerotrust_quests/engine/engine.dart';
import 'package:zerotrust_quests/engine/events.dart';
import 'package:zerotrust_quests/engine/hero.dart';
import 'package:zerotrust_quests/model/goal.dart';
import 'package:zerotrust_quests/model/quest.dart';
import 'package:zerotrust_quests/ui/achievements_page.dart';
import 'package:zerotrust_quests/ui/home_page.dart';

import 'support/app.dart';

Quest daily(String day, String goal, {bool done = true}) => Quest(
  id: 'daily-$goal-$day-0',
  goalId: goal,
  kind: QuestKind.daily,
  day: day,
  steps: [QuestStep(activity: 'pushups', target: 10, progress: done ? 10 : 0)],
  difficulty: 1,
  xp: 30,
  gold: 7,
);

void main() {
  group('seasonal events', () {
    test('Hanukkah runs eight days from 25 Kislev', () {
      final on = SeasonalEvents.runningOn('2026-12-05');
      final h = on.singleWhere((r) => r.event.id == 'hanukkah');
      expect(h.start, '2026-12-05');
      expect(h.end, '2026-12-12');
      expect(h.days, 8);
      expect(
        SeasonalEvents.runningOn('2026-12-13').map((r) => r.event.id),
        isNot(contains('hanukkah')),
      );
      // Hanukkah 2027 ends in January 2028, next to the new year event.
      expect(SeasonalEvents.runningOn('2028-01-01').map((r) => r.event.id), [
        'hanukkah',
        'newYear',
      ]);
    });

    test('summer steps runs July and August', () {
      expect(SeasonalEvents.runningOn('2027-07-01').map((r) => r.event.id), [
        'summerSteps',
      ]);
      expect(SeasonalEvents.runningOn('2027-09-01'), isEmpty);
    });

    test('joining makes an epic; joined or turned down, no more offer', () {
      final run = SeasonalEvents.runningOn('2026-12-06').single;
      final q = SeasonalEvents.questFor(run);
      expect(q.id, 'event-hanukkah-2026-12-05');
      expect(q.goalId, isEmpty);
      expect(q.kind, QuestKind.epic);
      expect(q.mode, EpicMode.streak);
      expect(q.steps.single.target, 8);
      expect(SeasonalEvents.offers([q], '2026-12-06'), isEmpty);
      expect(
        SeasonalEvents.offers([
          q.copyWith(declined: DeclineReason.notToday),
        ], '2026-12-06'),
        isEmpty,
      );
      expect(SeasonalEvents.offers(const [], '2026-12-06'), hasLength(1));
    });

    test('an event counts every goal\'s dailies, and wins its emblem', () {
      final run = SeasonalEvents.runningOn('2026-12-06').single;
      final event = SeasonalEvents.questFor(run);
      final quests = [
        event,
        for (var d = 5; d <= 12; d++)
          daily(
            '2026-12-${d.toString().padLeft(2, '0')}',
            d.isEven ? 'a' : 'b',
          ),
        daily('2026-12-13', 'a'), // after the event
      ];
      expect(QuestEngine.epicSteps(event, quests).single.progress, 8);
      expect(QuestEngine.epicDone(event, quests), isTrue);
      final stats = HeroStats.compute(quests, const [], '2026-12-13');
      expect(stats.eventsDone, 1);
      expect(stats.owned, contains('emblem:candle'));
      expect(
        Shop.unlocked(
          Shop.emblems.firstWhere((e) => e.id == 'candle'),
          'emblem',
          stats,
        ),
        isTrue,
      );
      expect(
        Shop.unlocked(
          Shop.emblems.firstWhere((e) => e.id == 'sun'),
          'emblem',
          stats,
        ),
        isFalse,
      );
    });

    test('a goal\'s own epic still counts only that goal', () {
      const epic = Quest(
        id: 'epic-a-2026-12-01',
        goalId: 'a',
        kind: QuestKind.epic,
        day: '2026-12-01',
        deadline: '2026-12-07',
        steps: [QuestStep(activity: 'streak', target: 3)],
        difficulty: 1,
        xp: 100,
        gold: 30,
        mode: EpicMode.streak,
      );
      final quests = [
        epic,
        daily('2026-12-01', 'a'),
        daily('2026-12-02', 'b'),
        daily('2026-12-03', 'b'),
      ];
      expect(QuestEngine.epicSteps(epic, quests).single.progress, 1);
    });
  });

  group('achievements', () {
    test('worked out from the stats', () {
      final quests = [
        for (var d = 1; d <= 10; d++)
          daily('2026-11-${d.toString().padLeft(2, '0')}', 'a'),
      ];
      final stats = HeroStats.compute(quests, const [], '2026-11-10');
      final list = Achievements.of(stats);
      bool on(String id) =>
          list.firstWhere((a) => a.achievement.id == id).unlocked;
      expect(on('firstQuest'), isTrue);
      expect(on('dailies10'), isTrue);
      expect(on('dailies50'), isFalse);
      expect(on('streak7'), isTrue);
      expect(on('streak30'), isFalse);
      expect(on('firstBoss'), isFalse);
      final fifty = list.firstWhere((a) => a.achievement.id == 'dailies50');
      expect(fifty.shown, 10);
      expect(fifty.ratio, closeTo(0.2, 1e-9));
    });
  });

  group('screens', () {
    testWidgets('during Hanukkah, Today offers the event; joining adds it', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360 * 3, 1600 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        app(
          const HomePage(),
          day: '2026-12-06',
          goals: const [
            Goal(
              id: 'a',
              category: GoalCategory.fitness,
              createdDay: '2026-11-01',
            ),
          ],
          quests: [daily('2026-12-06', 'a', done: false)],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Hanukkah lights'), findsOneWidget);
      final join = find.widgetWithText(FilledButton, 'Join');
      final notNow = find.widgetWithText(OutlinedButton, 'Not now');
      // Side by side, both with room.
      expect(tester.getRect(join).width, greaterThan(80));
      expect(tester.getRect(notNow).right, lessThan(tester.getRect(join).left));
      await tester.tap(join);
      await tester.pumpAndSettle();
      expect(
        repo.quests.where((q) => q.id == 'event-hanukkah-2026-12-05'),
        hasLength(1),
      );
      expect(find.widgetWithText(FilledButton, 'Join'), findsNothing);
      await tester.tap(find.text('Epics'));
      await tester.pumpAndSettle();
      expect(find.text('Hanukkah lights'), findsOneWidget);
    });

    testWidgets('the hero tab opens the achievements gallery', (tester) async {
      tester.view.physicalSize = const Size(360 * 3, 1600 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app(const HomePage()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hero'));
      await tester.pumpAndSettle();
      expect(
        find.text('0 of ${Achievements.all.length} unlocked'),
        findsOneWidget,
      );
      await tester.tap(find.text('Achievements'));
      await tester.pumpAndSettle();
      expect(find.byType(AchievementsPage), findsOneWidget);
      expect(find.text('First steps'), findsOneWidget);
      expect(find.text('Finish a daily quest'), findsOneWidget);
    });
  });
}
