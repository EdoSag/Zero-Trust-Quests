import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/quests_store.dart';
import '../engine/engine.dart';
import '../l10n/l10n.dart';
import '../model/goal.dart';
import '../model/quest.dart';
import 'common.dart';
import 'epics_tab.dart';
import 'goal_wizard.dart';
import 'hero_card.dart';
import 'labels.dart';
import 'quest_card.dart';

/// Today's daily quests, one per goal, under the hero card. Epic quests a
/// goal offers show here too.
class TodayTab extends ConsumerWidget {
  const TodayTab({super.key, this.onOpenHero});
  final VoidCallback? onOpenHero;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final goalsAsync = ref.watch(goalsProvider);
    final quests = ref.watch(questsProvider).value ?? const <Quest>[];
    final day = ref.watch(todayProvider);
    final goals = goalsAsync.value;
    if (goals == null) {
      return goalsAsync.hasError
          ? EmptyState(
              icon: Icons.error_outline,
              title: l.couldNotLoad,
              body: '${goalsAsync.error}',
            )
          : const Center(child: CircularProgressIndicator());
    }
    final active = [
      for (final g in goals)
        if (!g.archived) g,
    ];
    if (active.isEmpty) {
      return EmptyState(
        icon: Icons.flag_outlined,
        title: l.firstGoalTitle,
        body: l.firstGoalBody,
        action: FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
          icon: const Icon(Icons.add),
          label: Text(l.chooseGoal),
          onPressed: () => openGoalWizard(context),
        ),
      );
    }
    final cards = <Widget>[];
    final skipped = <Goal>[];
    for (final g in active) {
      final q = QuestEngine.currentDaily(g.id, quests, day);
      if (q == null) continue;
      if (q.declined == DeclineReason.notToday ||
          (q.declined != null &&
              QuestEngine.swapOf(q) >= QuestEngine.maxSwaps)) {
        skipped.add(g);
        continue;
      }
      if (q.declined != null) continue; // its swap is on the way
      cards.add(QuestCard(key: ValueKey(q.id), quest: q, goal: g));
    }
    final offers = [
      for (final g in active)
        if (QuestEngine.epicOffer(g, quests, day) case final offer?) (g, offer),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
      children: [
        HeroCard(onTap: onOpenHero),
        const SizedBox(height: 8),
        for (final (g, offer) in offers) EpicOfferCard(goal: g, offer: offer),
        if (cards.isEmpty && skipped.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
        ...cards,
        for (final g in skipped)
          Card(
            child: ListTile(
              leading: Icon(categoryIcon(g.category)),
              title: Text(goalName(l, g)),
              subtitle: Text(l.skippedToday),
            ),
          ),
      ],
    );
  }
}
