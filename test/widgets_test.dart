import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:zerotrust_quests/engine/hero.dart';
import 'package:zerotrust_quests/l10n/generated/app_l10n_en.dart';
import 'package:zerotrust_quests/l10n/generated/app_l10n_he.dart';
import 'package:zerotrust_quests/model/goal.dart';
import 'package:zerotrust_quests/model/quest.dart';
import 'package:zerotrust_quests/widgets/quests_widgets.dart';

const today = '2026-11-17';

const fit = Goal(
  id: 'g1',
  name: 'Run a marathon',
  category: GoalCategory.fitness,
  answers: {},
  createdDay: '2026-11-01',
);

const calm = Goal(
  id: 'g2',
  category: GoalCategory.mindfulness,
  answers: {},
  createdDay: '2026-11-01',
);

const fitQuest = Quest(
  id: 'daily-g1-2026-11-17-0',
  goalId: 'g1',
  kind: QuestKind.daily,
  day: today,
  steps: [
    QuestStep(activity: 'pushups', target: 25, progress: 25),
    QuestStep(activity: 'run', target: 1),
  ],
  difficulty: 1,
  xp: 30,
  gold: 10,
);

const calmQuest = Quest(
  id: 'daily-g2-2026-11-17-0',
  goalId: 'g2',
  kind: QuestKind.daily,
  day: today,
  steps: [QuestStep(activity: 'meditate', target: 10)],
  difficulty: 1,
  xp: 20,
  gold: 5,
  declined: DeclineReason.notToday,
);

Map<String, Object?> content({required bool details}) {
  final quests = [fitQuest, calmQuest];
  return QuestsWidgetContent.build(
    goals: const [fit, calm],
    quests: quests,
    stats: HeroStats.compute(quests, const [], today),
    day: today,
    details: details,
    l: AppL10nEn(),
  );
}

void main() {
  group('widget content', () {
    test('with details: step texts and goal names, declined left out', () {
      final c = content(details: true);
      expect(c['day'], today);
      expect(c['details'], true);
      final quests = c['quests']! as List;
      expect(quests, hasLength(1));
      final q = quests.single as Map;
      expect(q['id'], fitQuest.id);
      expect(q['goal'], 'Run a marathon');
      expect(q['xp'], 30);
      expect(q['steps'], [
        {'t': '25 push-ups', 'done': true},
        {'t': 'Run 1 km', 'done': false},
      ]);
      expect(c['todayDone'], false);
    });

    test('without details: nothing about the goals reaches the phone', () {
      final json = jsonEncode(content(details: false));
      expect(json, isNot(contains('marathon')));
      expect(json, isNot(contains('push-ups')));
      expect(json, isNot(contains('Run')));
      // The counts still work.
      final q = (content(details: false)['quests']! as List).single as Map;
      expect(q['steps'], [
        {'t': '', 'done': true},
        {'t': '', 'done': false},
      ]);
    });

    test('a finished quest makes today done and counts in the hero', () {
      final done = fitQuest.copyWith(
        steps: [for (final s in fitQuest.steps) s.withProgress(s.target)],
      );
      final c = QuestsWidgetContent.build(
        goals: const [fit],
        quests: [done],
        stats: HeroStats.compute([done], const [], today),
        day: today,
        details: false,
        l: AppL10nEn(),
      );
      expect(c['todayDone'], true);
      expect(c['xp'], 30);
      expect(c['gold'], 10);
      expect(c['streak'], 1);
      expect((c['titles']! as List).first, [1, 'Novice']);
    });

    test('texts leave the numbers to the widget, in both languages', () {
      final en = QuestsWidgetContent.texts(AppL10nEn());
      expect(en['steps_done'], r'%1$d of %2$d steps done');
      expect(en['level'], 'Level %d');
      expect(en['xp'], r'%1$d / %2$d XP');
      final he = QuestsWidgetContent.texts(AppL10nHe());
      expect(he['steps_done'], r'%1$d מתוך %2$d צעדים בוצעו');
      expect(he['streak'], 'רצף');
      expect(he.keys, en.keys);
    });
  });

  group('ticks from the home screen', () {
    test('parse', () {
      final t = WidgetTick.parse('7|daily-g1-2026-11-17-0|1')!;
      expect(t.seq, 7);
      expect(t.questId, 'daily-g1-2026-11-17-0');
      expect(t.step, 1);
      expect(WidgetTick.parse('nonsense'), isNull);
      expect(WidgetTick.parse('id|1'), isNull);
      expect(WidgetTick.parse('x|id|1'), isNull);
      expect(WidgetTick.parse('3|id|x'), isNull);
      expect(WidgetTick.parse('3||1'), isNull);
    });

    test('completes the step, whatever its amount', () {
      final q = const WidgetTick(
        1,
        'daily-g1-2026-11-17-0',
        1,
      ).applyTo(fitQuest)!;
      expect(q.steps[1].done, true);
      expect(q.steps[1].progress, 1);
      expect(q.steps[0], fitQuest.steps[0]);
      // Saved after midnight, it still counts for its own day.
      expect(q.day, today);
    });

    test('does nothing when there is nothing to do', () {
      // Already done, another quest, a missing step, a declined quest.
      expect(
        const WidgetTick(1, 'daily-g1-2026-11-17-0', 0).applyTo(fitQuest),
        isNull,
      );
      expect(const WidgetTick(1, 'other', 1).applyTo(fitQuest), isNull);
      expect(
        const WidgetTick(1, 'daily-g1-2026-11-17-0', 5).applyTo(fitQuest),
        isNull,
      );
      expect(
        const WidgetTick(1, 'daily-g2-2026-11-17-0', 0).applyTo(calmQuest),
        isNull,
      );
    });
  });
}
