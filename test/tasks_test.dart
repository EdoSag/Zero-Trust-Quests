import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zerotrust_quests/engine/hero.dart';
import 'package:zerotrust_quests/model/goal.dart';
import 'package:zerotrust_quests/model/quest.dart';
import 'package:zerotrust_quests/model/reward.dart';
import 'package:zerotrust_quests/tasks/linked_tasks.dart';
import 'package:zerotrust_quests/tasks/tasks_bridge.dart';
import 'package:zerotrust_quests/tasks/tasks_link_page.dart';
import 'package:zerotrust_quests/ui/today_tab.dart';

import 'support/app.dart';

const today = '2026-11-17';
const link = TasksLink(lists: {'default': '2026-11-15', 'work': today});

LinkedTask task(
  String id, {
  String list = 'default',
  bool completed = false,
  DateTime? completedAt,
  String? due,
  bool repeats = false,
  bool deleted = false,
  String priority = 'medium',
}) => LinkedTask(
  id: id,
  title: 'Task $id',
  listId: list,
  priority: priority,
  completed: completed,
  completedAt: completedAt,
  dueDay: due,
  repeats: repeats,
  deleted: deleted,
);

TaskRewardPlan plan(
  List<LinkedTask> tasks, {
  Set<String> existing = const {},
  Map<String, String> seen = const {},
  TasksLink l = link,
}) => TaskRewards.plan(
  tasks: tasks,
  link: l,
  existing: existing,
  seen: seen,
  today: today,
);

void main() {
  group('reading ZT Tasks', () {
    test('tasks are items without a kind; lists are task_list items', () {
      final snap = TasksSnapshot.fromItems([
        (
          't1',
          {
            'title': 'Buy milk',
            'priority': 'high',
            'isCompleted': true,
            'completedAt': '2026-11-17T09:30:00.000',
            'dueDate': '2026-11-17T00:00:00.000',
            'listId': 'work',
            'recurrence': null,
            'deletedAt': null,
          },
        ),
        (
          't2',
          {
            'title': 'No list',
            'recurrence': {'frequency': 'daily'},
          },
        ),
        ('l1', {'kind': 'task_list', 'name': 'Work'}),
        ('x', {'kind': 'template', 'title': 'A template'}),
        ('bad', {'title': 3}),
      ]);
      expect(snap.tasks.map((t) => t.id), ['t1', 't2']);
      final t1 = snap.tasks.first;
      expect(t1.listId, 'work');
      expect(t1.priority, 'high');
      expect(t1.completed, isTrue);
      expect(t1.dueDay, '2026-11-17');
      expect(t1.repeats, isFalse);
      expect(snap.tasks.last.listId, LinkedTaskList.defaultId);
      expect(snap.tasks.last.repeats, isTrue);
      // The default list is always there, first.
      expect(snap.lists.map((l) => l.id), ['default', 'l1']);
    });

    test('linking keeps the first day a list was linked', () {
      final on = const TasksLink().withList('a', on: true, day: '2026-11-10');
      final again = on.withList('a', on: true, day: '2026-11-17');
      expect(again.lists['a'], '2026-11-10');
      expect(again.withList('a', on: false, day: today).isOn, isFalse);
      expect(TasksLink.fromJson(on.toJson()).lists, on.lists);
    });
  });

  group('rewards', () {
    test('a task ticked off in a linked list earns XP by priority', () {
      final p = plan([
        task(
          'a',
          completed: true,
          completedAt: DateTime(2026, 11, 17, 10),
          priority: 'high',
        ),
        task('b', completed: true, completedAt: DateTime(2026, 11, 16, 10)),
      ]);
      expect(p.save.map((r) => r.id), ['task-a', 'task-b']);
      expect(p.save.first.xp, 10);
      expect(p.save.first.gold, 2);
      expect(p.save.first.day, today);
      expect(p.save.last.day, '2026-11-16');
      expect(p.save.first.source, RewardSource.task);
    });

    test('nothing for lists not linked, or tasks done before linking', () {
      final p = plan([
        task(
          'a',
          list: 'home',
          completed: true,
          completedAt: DateTime(2026, 11, 17),
        ),
        task(
          'b',
          list: 'work',
          completed: true,
          completedAt: DateTime(2026, 11, 16),
        ),
        task('c', completed: true, completedAt: DateTime(2026, 11, 14)),
      ]);
      expect(p.save, isEmpty);
    });

    test('a reward is made once; ticked back on, it goes', () {
      final done = task(
        'a',
        completed: true,
        completedAt: DateTime(2026, 11, 17),
      );
      expect(plan([done], existing: {'task-a'}).save, isEmpty);
      final undone = plan([task('a')], existing: {'task-a'});
      expect(undone.delete, ['task-a']);
      // Trashed after being done: the XP stays.
      expect(
        plan([task('a', deleted: true)], existing: {'task-a'}).delete,
        isEmpty,
      );
    });

    test('a repeating task earns a round when its due date moves on', () {
      final first = plan([task('r', repeats: true, due: today)]);
      expect(first.save, isEmpty);
      expect(first.seen, {'r': today});

      final rolled = plan([
        task('r', repeats: true, due: '2026-11-18'),
      ], seen: first.seen);
      expect(rolled.save.single.id, 'task-r-$today');
      expect(rolled.save.single.day, today);
      expect(rolled.seen, {'r': '2026-11-18'});

      // Pushing a future date further isn't doing it.
      final pushed = plan([
        task('r', repeats: true, due: '2026-11-25'),
      ], seen: rolled.seen);
      expect(pushed.save, isEmpty);
    });

    test('at most ten tasks a day count towards XP', () {
      final rewards = [
        for (var i = 0; i < 14; i++)
          Reward(
            id: 'task-${i.toString().padLeft(2, '0')}',
            source: RewardSource.task,
            day: today,
            xp: 8,
            gold: 2,
          ),
      ];
      final stats = HeroStats.compute(
        const [],
        const [],
        today,
        rewards: rewards,
      );
      expect(stats.tasksDone, HeroStats.tasksPerDay);
      expect(stats.xp, 80);
      expect(stats.gold, 20);
      expect(stats.streak, 0); // tasks don't keep the streak
    });
  });

  group('screens', () {
    testWidgets('pick the lists that count', (tester) async {
      await tester.pumpWidget(
        app(
          const TasksLinkPage(),
          overrides: [
            tasksSnapshotProvider.overrideWith(
              (ref) => Stream.value(
                const TasksSnapshot(
                  lists: [
                    LinkedTaskList(id: 'default', name: ''),
                    LinkedTaskList(id: 'work', name: 'Work'),
                  ],
                  refreshOk: true,
                ),
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('My Tasks'), findsOneWidget);
      expect(find.text('Work'), findsOneWidget);
      await tester.tap(find.text('Work'));
      await tester.pumpAndSettle();
      expect(repo.tasksLink.lists, {'work': '2026-11-17'});
      expect(
        tester
            .widget<SwitchListTile>(find.widgetWithText(SwitchListTile, 'Work'))
            .value,
        isTrue,
      );
    });

    testWidgets('today shows what ZT Tasks earned', (tester) async {
      await tester.pumpWidget(
        app(
          const Scaffold(body: TodayTab()),
          goals: const [
            Goal(
              id: 'g1',
              category: GoalCategory.fitness,
              createdDay: '2026-11-01',
            ),
          ],
          quests: const [
            Quest(
              id: 'daily-g1-2026-11-17-0',
              goalId: 'g1',
              kind: QuestKind.daily,
              day: today,
              steps: [QuestStep(activity: 'pushups', target: 20)],
              difficulty: 1,
              xp: 25,
              gold: 6,
            ),
          ],
          tasksLink: link,
          rewards: const [
            Reward(
              id: 'task-a',
              source: RewardSource.task,
              day: today,
              xp: 8,
              gold: 2,
            ),
            Reward(
              id: 'task-b',
              source: RewardSource.task,
              day: today,
              xp: 10,
              gold: 2,
            ),
            Reward(
              id: 'task-c',
              source: RewardSource.task,
              day: '2026-11-16',
              xp: 8,
              gold: 2,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      final line = find.text('ZT Tasks today: 2 done, 18 XP');
      expect(line, findsOneWidget);
      // Under the day's quest.
      expect(
        tester.getRect(line).top,
        greaterThan(tester.getRect(find.text('20 push-ups')).bottom),
      );
    });
  });
}
