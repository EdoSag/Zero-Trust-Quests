import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zerotrust_quests/engine/engine.dart';
import 'package:zerotrust_quests/model/goal.dart';
import 'package:zerotrust_quests/model/quest.dart';
import 'package:zerotrust_quests/ui/home_page.dart';

import 'support/app.dart';

const fit = Goal(
  id: 'g1',
  category: GoalCategory.fitness,
  answers: {'time': 'min20'},
  createdDay: '2026-11-01',
);

const today = '2026-11-17';

/// A quest with one counted and one yes/no step, so both can be tested.
const quest = Quest(
  id: 'daily-g1-2026-11-17-0',
  goalId: 'g1',
  kind: QuestKind.daily,
  day: today,
  steps: [
    QuestStep(activity: 'pushups', target: 20),
    QuestStep(activity: 'custom', label: 'Stretch', target: 1),
  ],
  difficulty: 1,
  xp: 35,
  gold: 8,
);

void main() {
  testWidgets('first run: pick a goal, answer, and get a quest', (
    tester,
  ) async {
    await tester.pumpWidget(app(const HomePage()));
    await tester.pumpAndSettle();
    expect(find.text('What do you want to get better at?'), findsOneWidget);
    await tester.tap(find.text('Choose a goal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get fitter'));
    await tester.pumpAndSettle();
    // Level, push-ups, running, focus, time: five questions.
    for (var i = 0; i < 4; i++) {
      expect(find.text('Next'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('About 40 minutes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start questing'));
    await tester.pumpAndSettle();

    expect(repo.goals.single.category, GoalCategory.fitness);
    expect(repo.goals.single.answers['time'], 'min40');
    final made = repo.quests.single;
    expect(made.day, today);
    expect(made.steps, hasLength(3));
    expect(find.text('Get fitter'), findsOneWidget);
    expect(find.text('Daily quest · difficulty 1×'), findsOneWidget);
  });

  testWidgets('the quest sits under the hero card, steps log and complete it', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(const HomePage(), goals: [fit], quests: [quest]),
    );
    await tester.pumpAndSettle();

    final hero = tester.getRect(find.text('Level 1 · Novice'));
    final title = tester.getRect(find.text('20 push-ups'));
    expect(title.top, greaterThan(hero.bottom));

    await tester.tap(find.byTooltip('Log progress'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('+20 (the rest)'));
    await tester.pumpAndSettle();
    expect(repo.quests.single.steps.first.progress, 20);
    expect(find.text('Quest complete!'), findsNothing);

    await tester.tap(find.text('Stretch'));
    await tester.pumpAndSettle();
    expect(find.text('Quest complete!'), findsOneWidget);
    expect(find.text('+35 XP'), findsWidgets);
    expect(repo.quests.single.claimed, isTrue);
    await tester.tap(find.text('Onward!'));
    await tester.pumpAndSettle();
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('8 gold'), findsWidgets);
  });

  testWidgets('declining as too hard swaps in an easier quest', (tester) async {
    await tester.pumpWidget(
      app(const HomePage(), goals: [fit], quests: [quest]),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Decline quest'));
    await tester.pumpAndSettle();
    expect(find.text('Your first decline today is free.'), findsOneWidget);
    await tester.tap(find.text('Too hard'));
    await tester.pumpAndSettle();

    final swap = repo.quests.firstWhere((q) => q.id.endsWith('-1'));
    expect(swap.difficulty, 0.85);
    expect(
      repo.quests.firstWhere((q) => q.id == quest.id).declined,
      DeclineReason.tooHard,
    );
    expect(find.text('Daily quest · difficulty 0.85×'), findsOneWidget);

    // The second decline of the day costs gold, which a new hero lacks.
    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Decline quest'));
    await tester.pumpAndSettle();
    expect(find.textContaining('costs 10 gold'), findsOneWidget);
    await tester.tap(find.text('Something else'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Not enough gold'), findsOneWidget);
    expect(repo.quests, hasLength(2));
  });

  testWidgets('epic quests are offered after three completed dailies', (
    tester,
  ) async {
    Quest done(String day) {
      final q = QuestEngine.daily(fit, day, difficulty: 1);
      return q.copyWith(
        steps: [for (final s in q.steps) s.withProgress(s.target)],
      );
    }

    await tester.pumpWidget(
      app(
        const HomePage(),
        goals: [fit],
        quests: [
          done('2026-11-14'),
          done('2026-11-15'),
          done('2026-11-16'),
          quest,
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('New epic quest · Get fitter'), findsOneWidget);
    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();
    expect(repo.quests.where((q) => q.kind == QuestKind.epic), hasLength(1));
    expect(find.text('New epic quest · Get fitter'), findsNothing);

    await tester.tap(find.text('Epics'));
    await tester.pumpAndSettle();
    expect(find.text('In progress'), findsOneWidget);
  });

  testWidgets('the shop refuses what gold cannot buy', (tester) async {
    await tester.pumpWidget(
      app(const HomePage(), goals: [fit], quests: [quest]),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hero'));
    await tester.pumpAndSettle();
    // Bring the streak freeze above the navigation bar.
    await tester.drag(find.byType(ListView).first, const Offset(0, -250));
    await tester.pumpAndSettle();
    await tester.tap(find.text('60 gold'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Not enough gold'), findsOneWidget);
    expect(repo.purchases, isEmpty);
  });
}
