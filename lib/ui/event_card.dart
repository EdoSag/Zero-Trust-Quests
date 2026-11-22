import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/quests_store.dart';
import '../engine/events.dart';
import '../l10n/l10n.dart';
import '../model/days.dart';
import '../model/quest.dart';
import 'common.dart';
import 'labels.dart';

/// "Seasonal event": join (it becomes an epic quest), or not now (not
/// offered again this time round).
class EventOfferCard extends ConsumerWidget {
  const EventOfferCard({super.key, required this.run});
  final EventRun run;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final e = run.event;
    const color = Color(0xFFEAB308);
    final until = MaterialLocalizations.of(
      context,
    ).formatMediumDate(dayOf(run.end));
    return Card(
      color: color.withValues(alpha: 0.10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(eventIcon(e.id), color: color),
                const SizedBox(width: 8),
                Expanded(child: Text(l.eventOffer(until), style: t.labelLarge)),
              ],
            ),
            const SizedBox(height: 8),
            Text(eventName(l, e.id), style: t.titleMedium),
            const SizedBox(height: 4),
            Text(eventBody(l, e.id), style: t.bodyMedium),
            const SizedBox(height: 4),
            Text(l.eventEmblemNote, style: t.bodySmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                RewardChip(
                  icon: Icons.auto_awesome,
                  text: l.xpAmount(e.xp),
                  color: xpColor,
                ),
                RewardChip(
                  icon: Icons.paid,
                  text: l.goldAmount(e.gold),
                  color: goldColor,
                ),
                RewardChip(icon: emblemIcon(e.emblem), text: l.eventOnly),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                    ),
                    onPressed: () => ref
                        .read(questsRepositoryProvider)
                        .saveQuest(
                          SeasonalEvents.questFor(
                            run,
                          ).copyWith(declined: DeclineReason.notToday),
                        ),
                    child: Text(l.notNow),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 44),
                    ),
                    onPressed: () async {
                      await ref
                          .read(questsRepositoryProvider)
                          .saveQuest(SeasonalEvents.questFor(run));
                      if (context.mounted) showSnack(context, l.eventJoined);
                    },
                    child: Text(l.eventJoin),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
