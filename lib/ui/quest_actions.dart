import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/quests_store.dart';
import '../engine/engine.dart';
import '../engine/hero.dart';
import '../l10n/l10n.dart';
import '../model/quest.dart';
import '../model/reward.dart';
import 'common.dart';
import 'labels.dart';

List<Quest> _replace(List<Quest> list, Quest q) => [
  for (final x in list)
    if (x.id != q.id) x,
  q,
];

/// Saves [updated] in place of its quest; celebrates when that completes
/// it (and when it brings a new level).
Future<void> saveProgress(
  BuildContext context,
  WidgetRef ref,
  Quest updated,
) async {
  final quests = ref.read(questsProvider).value ?? const <Quest>[];
  final purchases = ref.read(purchasesProvider).value ?? const <Purchase>[];
  final day = ref.read(todayProvider);
  final old = quests.where((q) => q.id == updated.id).firstOrNull;
  final wasDone = old != null && QuestEngine.completed(old, quests);
  final after = _replace(quests, updated);
  final nowDone = QuestEngine.completed(updated, after);
  var toSave = updated;
  final celebrate = nowDone && !wasDone && !updated.claimed;
  if (celebrate) toSave = updated.copyWith(claimed: true);
  await ref.read(questsRepositoryProvider).saveQuest(toSave);
  if (!celebrate || !context.mounted) return;
  // Rewards (ZT Tasks, parties) count towards the level too.
  final rewards = ref.read(rewardsProvider).value ?? const <Reward>[];
  final before = HeroStats.compute(quests, purchases, day, rewards: rewards);
  final now = HeroStats.compute(after, purchases, day, rewards: rewards);
  await showDialog<void>(
    context: context,
    builder: (ctx) => _Celebration(
      quest: updated,
      xp: now.xp - before.xp,
      gold: now.gold - before.gold,
      newLevel: now.level > before.level ? now.level : null,
    ),
  );
}

class _Celebration extends StatelessWidget {
  const _Celebration({
    required this.quest,
    required this.xp,
    required this.gold,
    this.newLevel,
  });
  final Quest quest;
  final int xp;
  final int gold;
  final int? newLevel;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    return AlertDialog(
      icon: const Icon(Icons.emoji_events, size: 48, color: goldColor),
      title: Text(quest.isDaily ? l.questComplete : l.epicComplete),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 8,
            alignment: WrapAlignment.center,
            children: [
              RewardChip(
                icon: Icons.auto_awesome,
                text: l.xpAmount(xp),
                color: xpColor,
              ),
              RewardChip(
                icon: Icons.paid,
                text: l.goldAmount(gold),
                color: goldColor,
              ),
            ],
          ),
          if (newLevel != null) ...[
            const SizedBox(height: 16),
            Text(
              l.levelUp(newLevel!),
              style: t.titleMedium,
              textAlign: TextAlign.center,
            ),
            Text(
              heroTitle(l, newLevel!),
              style: t.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: () => Navigator.pop(context),
          child: Text(l.onward),
        ),
      ],
    );
  }
}

/// Asks why, then declines [q]: free once a day, then for gold. A swap
/// follows unless the reason is "not today".
Future<void> declineQuest(BuildContext context, WidgetRef ref, Quest q) async {
  final l = context.l10n;
  final stats = ref.read(heroStatsProvider);
  final free = stats.freeDeclineLeft;
  final cost = free ? 0 : Shop.declinePrice;
  final reason = await showModalBottomSheet<DeclineReason>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
              child: Text(
                l.declineTitle,
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(free ? l.declineFree : l.declineCosts(cost)),
            ),
            for (final r in DeclineReason.values)
              ListTile(
                leading: Icon(switch (r) {
                  DeclineReason.tooHard => Icons.trending_down,
                  DeclineReason.tooEasy => Icons.trending_up,
                  DeclineReason.different => Icons.shuffle,
                  DeclineReason.notToday => Icons.event_busy,
                }),
                title: Text(declineReasonText(l, r)),
                subtitle: Text(switch (r) {
                  DeclineReason.tooHard => l.declineTooHardHint,
                  DeclineReason.tooEasy => l.declineTooEasyHint,
                  DeclineReason.different => l.declineDifferentHint,
                  DeclineReason.notToday => l.declineNotTodayHint,
                }),
                onTap: () => Navigator.pop(ctx, r),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
  if (reason == null || !context.mounted) return;
  if (cost > 0 && stats.gold < cost) {
    showSnack(context, l.notEnoughGold);
    return;
  }
  final repo = ref.read(questsRepositoryProvider);
  await repo.saveQuest(q.copyWith(declined: reason, declineCost: cost));
  final made = await repo.planDay(q.day);
  if (!context.mounted) return;
  if (reason != DeclineReason.notToday && made.isEmpty) {
    showSnack(context, l.noMoreSwaps);
  }
}

/// Asks for an amount for [step] of [q] and returns the step's new
/// progress, or null.
Future<double?> askAmount(
  BuildContext context,
  Quest q,
  QuestStep step, {
  bool best = false,
}) {
  return showModalBottomSheet<double>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _AmountSheet(step: step, best: best),
  );
}

class _AmountSheet extends StatefulWidget {
  const _AmountSheet({required this.step, required this.best});
  final QuestStep step;
  final bool best;

  @override
  State<_AmountSheet> createState() => _AmountSheetState();
}

class _AmountSheetState extends State<_AmountSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double? get _value =>
      double.tryParse(_controller.text.trim().replaceAll(',', '.'));

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = widget.step;
    final remaining = (s.target - s.progress)
        .clamp(0, double.infinity)
        .toDouble();
    final quick = <double>{
      if (remaining > 0) remaining,
      for (final f in [0.25, 0.5])
        if (s.target * f >= 1) (s.target * f).roundToDouble(),
      1,
    }.toList()..sort();
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(stepText(l, s), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(progressText(l, s)),
          const SizedBox(height: 16),
          if (!widget.best)
            Wrap(
              spacing: 8,
              children: [
                for (final v in quick)
                  ActionChip(
                    label: Text(
                      v == remaining ? l.addRest(fmtNum(v)) : '+${fmtNum(v)}',
                    ),
                    onPressed: () => Navigator.pop(context, s.progress + v),
                  ),
              ],
            ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: widget.best ? l.bestSoFar : l.amountDone,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (!widget.best)
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                    onPressed: _value == null
                        ? null
                        : () => Navigator.pop(context, _value),
                    child: Text(l.setTotal),
                  ),
                ),
              if (!widget.best) const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                  onPressed: _value == null
                      ? null
                      : () => Navigator.pop(
                          context,
                          widget.best ? _value : s.progress + _value!,
                        ),
                  child: Text(widget.best ? l.save : l.add),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
