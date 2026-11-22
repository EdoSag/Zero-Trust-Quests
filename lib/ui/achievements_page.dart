import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/quests_store.dart';
import '../engine/achievements.dart';
import '../l10n/l10n.dart';
import 'common.dart';
import 'labels.dart';

/// On the Hero tab: how many achievements are unlocked, opening the
/// gallery.
class AchievementsTile extends ConsumerWidget {
  const AchievementsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final list = Achievements.of(ref.watch(heroStatsProvider));
    final done = list.where((a) => a.unlocked).length;
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0x22D97706),
          foregroundColor: goldColor,
          child: Icon(Icons.emoji_events),
        ),
        title: Text(l.achievements),
        subtitle: Text(l.achievementsCount(done, list.length)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const AchievementsPage()),
        ),
      ),
    );
  }
}

/// Every achievement: unlocked ones in colour, the rest with how far
/// along they are.
class AchievementsPage extends ConsumerWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final list = Achievements.of(ref.watch(heroStatsProvider));
    final done = list.where((a) => a.unlocked).length;
    return Scaffold(
      appBar: AppBar(title: Text(l.achievements)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Text(l.achievementsCount(done, list.length)),
          ),
          for (final a in list) _AchievementCard(progress: a),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.progress});
  final AchievementProgress progress;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final a = progress.achievement;
    final on = progress.unlocked;
    return Card(
      color: on ? goldColor.withValues(alpha: 0.08) : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: on
              ? goldColor.withValues(alpha: 0.2)
              : scheme.surfaceContainerHighest,
          foregroundColor: on ? goldColor : scheme.outline,
          child: Icon(on ? achievementIcon(a.metric) : Icons.lock_outline),
        ),
        title: Text(achievementTitle(l, a.id)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(achievementBody(l, a)),
            if (!on && a.target > 1) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(value: progress.ratio),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l.progressOf(fmtNum(progress.shown), fmtNum(a.target)),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: on ? const Icon(Icons.check_circle, color: goldColor) : null,
      ),
    );
  }
}
