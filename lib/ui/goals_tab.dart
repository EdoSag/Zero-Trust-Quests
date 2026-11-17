import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/quests_store.dart';
import '../engine/engine.dart';
import '../l10n/l10n.dart';
import '../model/days.dart';
import '../model/goal.dart';
import '../model/quest.dart';
import 'common.dart';
import 'goal_wizard.dart';
import 'labels.dart';
import 'quest_card.dart';

/// The user's goals, with how the last week went and the current
/// difficulty of each.
class GoalsTab extends ConsumerWidget {
  const GoalsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final goals = ref.watch(goalsProvider).value ?? const <Goal>[];
    final quests = ref.watch(questsProvider).value ?? const <Quest>[];
    final day = ref.watch(todayProvider);
    if (goals.isEmpty) {
      return EmptyState(
        icon: Icons.flag_outlined,
        title: l.firstGoalTitle,
        body: l.firstGoalBody,
      );
    }
    final active = [
      for (final g in goals)
        if (!g.archived) g,
    ];
    final archived = [
      for (final g in goals)
        if (g.archived) g,
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
      children: [
        for (final g in active) _GoalTile(goal: g, quests: quests, day: day),
        if (archived.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 4),
            child: Text(
              l.archivedGoals,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        for (final g in archived) _GoalTile(goal: g, quests: quests, day: day),
      ],
    );
  }
}

/// Daily quests completed / made in the last 7 days (each day counted
/// once, by its latest swap).
(int, int) weekScore(Goal g, List<Quest> quests, String day) {
  final from = addDays(day, -6);
  final days = {
    for (final q in quests)
      if (q.isDaily && q.goalId == g.id && q.day.compareTo(from) >= 0) q.day,
  };
  var done = 0;
  var made = 0;
  for (final d in days) {
    final q = QuestEngine.currentDaily(g.id, quests, d);
    if (q == null || q.declined == DeclineReason.notToday) continue;
    made++;
    if (QuestEngine.completed(q, quests)) done++;
  }
  return (done, made);
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({
    required this.goal,
    required this.quests,
    required this.day,
  });
  final Goal goal;
  final List<Quest> quests;
  final String day;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final (done, made) = weekScore(goal, quests, day);
    final difficulty = QuestEngine.difficultyFor(goal, quests, day);
    final color = categoryColor(goal.category);
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          foregroundColor: color,
          child: Icon(categoryIcon(goal.category)),
        ),
        title: Text(goalName(l, goal)),
        subtitle: Text(
          '${l.weekDone(done, made)} · ${l.difficultyValue(fmtNum(double.parse(difficulty.toStringAsFixed(1))))}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => GoalPage(goalId: goal.id)),
        ),
      ),
    );
  }
}

/// One goal: its numbers, its quests, and edit / archive / delete.
class GoalPage extends ConsumerWidget {
  const GoalPage({super.key, required this.goalId});
  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final goals = ref.watch(goalsProvider).value ?? const <Goal>[];
    final goal = goals.where((g) => g.id == goalId).firstOrNull;
    if (goal == null) {
      return Scaffold(appBar: AppBar());
    }
    final quests = ref.watch(questsProvider).value ?? const <Quest>[];
    final day = ref.watch(todayProvider);
    final mine = [
      for (final q in quests)
        if (q.goalId == goal.id && q.isDaily) q,
    ];
    final history = <Quest>[];
    for (final d in {
      for (final q in mine) q.day,
    }.toList()..sort((a, b) => b.compareTo(a))) {
      if (QuestEngine.currentDaily(goal.id, quests, d) case final q?) {
        history.add(q);
      }
    }
    final done = mine.where((q) => QuestEngine.completed(q, quests)).length;
    final repo = ref.read(questsRepositoryProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(goalName(l, goal)),
        actions: [
          PopupMenuButton<String>(
            tooltip: l.more,
            onSelected: (v) async {
              switch (v) {
                case 'edit':
                  await openGoalWizard(context, edit: goal);
                case 'archive':
                  await repo.saveGoal(goal.copyWith(archived: !goal.archived));
                  if (!goal.archived) await repo.planDay(day);
                case 'delete':
                  if (await confirm(
                    context,
                    title: l.deleteGoalTitle,
                    body: l.deleteGoalBody,
                    action: l.delete,
                    destructive: true,
                  )) {
                    await repo.deleteGoal(goal.id);
                    if (context.mounted) Navigator.pop(context);
                  }
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'edit', child: Text(l.editAnswers)),
              PopupMenuItem(
                value: 'archive',
                child: Text(goal.archived ? l.unarchiveGoal : l.archiveGoal),
              ),
              PopupMenuItem(value: 'delete', child: Text(l.delete)),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 24,
                runSpacing: 12,
                children: [
                  _Stat(label: l.statQuestsDone, value: '$done'),
                  _Stat(
                    label: l.statDifficulty,
                    value:
                        '${fmtNum(double.parse(QuestEngine.difficultyFor(goal, quests, day).toStringAsFixed(2)))}×',
                  ),
                  _Stat(label: l.statSince, value: goal.createdDay),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Text(l.difficultyExplained),
          ),
          for (final q in history.take(30))
            QuestCard(quest: q, goal: goal, readOnly: q.day != day),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: t.titleLarge),
        Text(label, style: t.bodySmall),
      ],
    );
  }
}
