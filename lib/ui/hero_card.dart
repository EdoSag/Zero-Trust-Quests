import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/quests_store.dart';
import '../l10n/l10n.dart';
import 'common.dart';
import 'labels.dart';

/// Level, title, XP to the next level, gold and streak.
class HeroCard extends ConsumerWidget {
  const HeroCard({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final stats = ref.watch(heroStatsProvider);
    final look = ref.watch(heroLookProvider).value;
    final color = heroColor(look?.color ?? 'teal');
    final name = (look?.name ?? '').trim();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.15),
                      border: Border.all(color: color, width: 3),
                    ),
                    child: Icon(
                      emblemIcon(look?.emblem ?? 'shield'),
                      color: color,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isEmpty ? heroTitle(l, stats.level) : name,
                          style: t.titleLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          l.levelTitle(stats.level, heroTitle(l, stats.level)),
                          style: t.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: stats.xpForNext == 0
                      ? 0
                      : stats.xpIntoLevel / stats.xpForNext,
                  minHeight: 10,
                  color: xpColor,
                  backgroundColor: xpColor.withValues(alpha: 0.15),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l.xpToNext(stats.xpIntoLevel, stats.xpForNext, stats.level + 1),
                style: t.bodySmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  RewardChip(
                    icon: Icons.paid,
                    text: l.goldAmount(stats.gold),
                    color: goldColor,
                  ),
                  RewardChip(
                    icon: Icons.local_fire_department,
                    text: l.streakDays(stats.streak),
                    color: const Color(0xFFEA580C),
                  ),
                  if (stats.freezes > 0)
                    RewardChip(
                      icon: Icons.ac_unit,
                      text: l.freezesHeld(stats.freezes),
                      color: const Color(0xFF0EA5E9),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
