import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/quests_store.dart';
import '../engine/hero.dart';
import '../l10n/l10n.dart';
import '../model/reward.dart';
import '../ui/common.dart';

/// Under today's quests: what ZT Tasks earned today, once a list is linked
/// and a task was ticked off.
class TasksTodayCard extends ConsumerWidget {
  const TasksTodayCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final link = ref.watch(tasksLinkProvider).value;
    if (link == null || !link.isOn) return const SizedBox.shrink();
    final day = ref.watch(todayProvider);
    final todays = [
      for (final r in ref.watch(rewardsProvider).value ?? const <Reward>[])
        if (r.source == RewardSource.task && r.day == day) r,
    ]..sort((a, b) => a.id.compareTo(b.id));
    if (todays.isEmpty) return const SizedBox.shrink();
    final counted = todays.take(HeroStats.tasksPerDay);
    final xp = counted.fold(0, (a, r) => a + r.xp);
    final l = context.l10n;
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.checklist)),
        title: Text(l.tasksToday(counted.length, xp)),
        trailing: const Icon(Icons.auto_awesome, color: xpColor),
      ),
    );
  }
}
