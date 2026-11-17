import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/quests_store.dart';
import '../engine/catalog.dart';
import '../engine/engine.dart';
import '../l10n/l10n.dart';
import '../model/days.dart';
import '../model/goal.dart';
import '../model/quest.dart';
import 'common.dart';
import 'labels.dart';
import 'quest_actions.dart';

/// A quest with its steps, progress and reward. Steps are logged by tapping
/// them; a daily quest can be declined from its menu.
class QuestCard extends ConsumerWidget {
  const QuestCard({
    super.key,
    required this.quest,
    this.goal,
    this.readOnly = false,
  });

  final Quest quest;
  final Goal? goal;
  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final quests = ref.watch(questsProvider).value ?? const <Quest>[];
    final today = ref.watch(todayProvider);
    final steps = quest.isDaily
        ? quest.steps
        : QuestEngine.epicSteps(quest, quests);
    final done = QuestEngine.completed(quest, quests);
    final open =
        !readOnly &&
        quest.declined == null &&
        !done &&
        (quest.isDaily
            ? quest.day == today
            : (quest.deadline ?? today).compareTo(today) >= 0);
    final color = goal == null
        ? theme.colorScheme.primary
        : categoryColor(goal!.category);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              foregroundColor: color,
              child: Icon(
                goal == null
                    ? Icons.flag_outlined
                    : categoryIcon(goal!.category),
              ),
            ),
            title: Text(
              questTitle(l, quest, goal),
              style: theme.textTheme.titleMedium,
            ),
            subtitle: Text(_subtitle(l, today)),
            trailing: open && quest.isDaily
                ? PopupMenuButton<String>(
                    tooltip: l.more,
                    onSelected: (_) => declineQuest(context, ref, quest),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'decline',
                        child: Text(l.declineAction),
                      ),
                    ],
                  )
                : null,
          ),
          for (var i = 0; i < steps.length; i++)
            _StepRow(quest: quest, index: i, step: steps[i], enabled: open),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                RewardChip(
                  icon: Icons.auto_awesome,
                  text: l.xpAmount(quest.xp),
                  color: xpColor,
                ),
                const SizedBox(width: 8),
                RewardChip(
                  icon: Icons.paid,
                  text: l.goldAmount(quest.gold),
                  color: goldColor,
                ),
                const Spacer(),
                if (done)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l.completed,
                        style: TextStyle(color: theme.colorScheme.primary),
                      ),
                    ],
                  )
                else if (quest.declined != null)
                  Text(
                    declineReasonText(l, quest.declined!),
                    style: theme.textTheme.bodySmall,
                  )
                else if (!open && !readOnly)
                  Text(l.missed, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _subtitle(AppL10n l, String today) {
    if (quest.isDaily) {
      final d = l.difficultyValue(
        fmtNum(double.parse(quest.difficulty.toStringAsFixed(2))),
      );
      return quest.day == today ? '${l.dailyQuest} · $d' : '${quest.day} · $d';
    }
    final left = daysBetween(today, quest.deadline ?? today);
    return left < 0 ? l.endedOn(quest.deadline ?? '') : l.daysLeft(left + 1);
  }
}

class _StepRow extends ConsumerWidget {
  const _StepRow({
    required this.quest,
    required this.index,
    required this.step,
    required this.enabled,
  });

  final Quest quest;
  final int index;
  final QuestStep step;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final check = isCheckStep(step);
    final fromHealth = activityById[step.activity]?.health != null;
    final streak = step.activity == 'streak';
    Future<void> setProgress(double p) async {
      // Start from the latest stored quest: Health Connect or another
      // phone may have changed other steps while the amount sheet was open.
      final latest =
          (ref.read(questsProvider).value ?? const <Quest>[])
              .where((q) => q.id == quest.id)
              .firstOrNull ??
          quest;
      if (index >= latest.steps.length) return;
      final stored = latest.steps[index];
      // An epic keeps only what was logged by hand on top of the dailies.
      final value = latest.isDaily || latest.mode == EpicMode.best
          ? p
          : stored.progress + (p - step.progress);
      final steps = [...latest.steps]..[index] = stored.withProgress(value);
      if (!context.mounted) return;
      await saveProgress(context, ref, latest.copyWith(steps: steps));
    }

    if (check) {
      return CheckboxListTile(
        value: step.done,
        title: Text(stepText(l, step)),
        controlAffinity: ListTileControlAffinity.leading,
        onChanged: enabled
            ? (v) => setProgress(v == true ? step.target : 0)
            : null,
      );
    }
    return ListTile(
      leading: Icon(
        step.done ? Icons.check_circle : Icons.radio_button_unchecked,
        color: step.done ? theme.colorScheme.primary : null,
      ),
      title: Text(stepText(l, step)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: step.ratio, minHeight: 6),
              ),
            ),
            const SizedBox(width: 8),
            Text(progressText(l, step)),
            if (fromHealth) ...[
              const SizedBox(width: 4),
              Tooltip(
                message: l.fromHealthConnect,
                child: Icon(
                  Icons.favorite_border,
                  size: 14,
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ],
        ),
      ),
      trailing: enabled && !streak
          ? IconButton(
              tooltip: l.logProgress,
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () async {
                final p = await askAmount(
                  context,
                  quest,
                  step,
                  best: !quest.isDaily && quest.mode == EpicMode.best,
                );
                if (p != null && context.mounted) await setProgress(p);
              },
            )
          : null,
    );
  }
}
