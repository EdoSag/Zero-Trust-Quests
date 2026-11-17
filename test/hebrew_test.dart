import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_trust_core/zero_trust_core.dart';
import 'package:zerotrust_quests/model/goal.dart';
import 'package:zerotrust_quests/model/quest.dart';
import 'package:zerotrust_quests/ui/home_page.dart';

import 'support/app.dart';

void main() {
  testWidgets('Hebrew: right to left, translated, nothing overflows', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360 * 3, 740 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      app(
        const HomePage(),
        locale: ZtLanguages.hebrew,
        goals: const [
          Goal(
            id: 'g',
            category: GoalCategory.nutrition,
            createdDay: '2026-11-01',
          ),
        ],
        quests: const [
          Quest(
            id: 'daily-g-2026-11-17-0',
            goalId: 'g',
            kind: QuestKind.daily,
            day: '2026-11-17',
            steps: [QuestStep(activity: 'water', target: 6, progress: 2)],
            difficulty: 1,
            xp: 20,
            gold: 5,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('שתייה של 6 כוסות מים'), findsOneWidget);
    expect(find.text('2 מתוך 6'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(HomePage))),
      TextDirection.rtl,
    );
    // The hero card's avatar is on the right in Hebrew.
    final level = tester.getRect(find.text('שלב 1 · מתחיל'));
    final shield = tester.getRect(find.byIcon(Icons.shield).first);
    expect(shield.left, greaterThan(level.right));
    for (final tab in ['אפיות', 'מטרות', 'גיבור']) {
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: tab);
    }
  });
}
