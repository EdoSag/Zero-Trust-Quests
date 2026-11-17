import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/quests_store.dart';
import '../engine/hero.dart';
import '../l10n/l10n.dart';
import '../model/quest.dart';
import 'common.dart';
import 'hero_card.dart';
import 'labels.dart';

/// The hero: level, records, and the shop where gold buys streak freezes,
/// emblems and colours. Levels unlock some of them for free.
class HeroTab extends ConsumerWidget {
  const HeroTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final stats = ref.watch(heroStatsProvider);
    final look = ref.watch(heroLookProvider).value ?? const HeroLook();
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
      children: [
        const HeroCard(),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                _Stat(l.statDailies, '${stats.dailiesDone}'),
                _Stat(l.statEpics, '${stats.epicsDone}'),
                _Stat(l.statBestStreak, '${stats.bestStreak}'),
                _Stat(l.statTotalXp, '${stats.xp}'),
              ],
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.badge_outlined),
          title: Text(l.heroName),
          subtitle: Text(look.name.isEmpty ? l.notSet : look.name),
          onTap: () => _rename(context, ref, look),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 4),
          child: Text(l.shop, style: t.titleMedium),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(l.shopHint),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.ac_unit, color: Color(0xFF0EA5E9)),
            title: Text(l.streakFreeze),
            subtitle: Text(l.streakFreezeHint(Shop.maxFreezes)),
            trailing: FilledButton.tonal(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
              onPressed: stats.freezes >= Shop.maxFreezes
                  ? null
                  : () => _buy(context, ref, Shop.freeze, Shop.freezePrice),
              child: Text(l.goldAmount(Shop.freezePrice)),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
          child: Text(l.emblems, style: t.titleSmall),
        ),
        _ItemGrid(
          kind: 'emblem',
          items: Shop.emblems,
          selected: look.emblem,
          stats: stats,
          builder: (item, color) =>
              Icon(emblemIcon(item.id), color: color, size: 28),
          onWear: (id) => ref
              .read(questsRepositoryProvider)
              .saveHero(look.copyWith(emblem: id)),
          onBuy: (item) => _buy(context, ref, 'emblem:${item.id}', item.price),
          heroColor: heroColor(look.color),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
          child: Text(l.colors, style: t.titleSmall),
        ),
        _ItemGrid(
          kind: 'color',
          items: Shop.colors,
          selected: look.color,
          stats: stats,
          builder: (item, _) =>
              CircleAvatar(radius: 14, backgroundColor: heroColor(item.id)),
          onWear: (id) => ref
              .read(questsRepositoryProvider)
              .saveHero(look.copyWith(color: id)),
          onBuy: (item) => _buy(context, ref, 'color:${item.id}', item.price),
          heroColor: heroColor(look.color),
        ),
      ],
    );
  }

  Future<void> _buy(
    BuildContext context,
    WidgetRef ref,
    String item,
    int price,
  ) async {
    final l = context.l10n;
    final stats = ref.read(heroStatsProvider);
    if (stats.gold < price) {
      showSnack(context, l.notEnoughGold);
      return;
    }
    if (!await confirm(
      context,
      title: l.buyTitle,
      body: l.buyBody(price),
      action: l.buy,
    )) {
      return;
    }
    await ref
        .read(questsRepositoryProvider)
        .savePurchase(
          Purchase(
            id: QuestsRepository.newId(),
            item: item,
            cost: price,
            day: ref.read(todayProvider),
          ),
        );
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    HeroLook look,
  ) async {
    final l = context.l10n;
    final c = TextEditingController(text: look.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.heroName),
        content: TextField(
          controller: c,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          maxLength: 30,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, c.text.trim()),
            child: Text(l.save),
          ),
        ],
      ),
    );
    if (name != null) {
      await ref
          .read(questsRepositoryProvider)
          .saveHero(look.copyWith(name: name));
    }
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);
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

class _ItemGrid extends StatelessWidget {
  const _ItemGrid({
    required this.kind,
    required this.items,
    required this.selected,
    required this.stats,
    required this.builder,
    required this.onWear,
    required this.onBuy,
    required this.heroColor,
  });

  final String kind;
  final List<ShopItem> items;
  final String selected;
  final HeroStats stats;
  final Widget Function(ShopItem item, Color color) builder;
  final ValueChanged<String> onWear;
  final ValueChanged<ShopItem> onBuy;
  final Color heroColor;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in items)
          () {
            final open = Shop.unlocked(item, kind, stats);
            final worn = item.id == selected;
            final String label;
            if (worn) {
              label = l.wearing;
            } else if (open) {
              label = l.wear;
            } else if (item.price > 0) {
              label = l.goldAmount(item.price);
            } else {
              label = l.levelShort(item.level);
            }
            return SizedBox(
              width: 92,
              child: Card(
                color: worn ? scheme.primaryContainer : null,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: worn
                      ? null
                      : open
                      ? () => onWear(item.id)
                      : item.price > 0
                      ? () => onBuy(item)
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      children: [
                        Opacity(
                          opacity: open ? 1 : 0.4,
                          child: builder(
                            item,
                            open ? heroColor : scheme.outline,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!open)
                              Icon(
                                item.price > 0
                                    ? Icons.paid
                                    : Icons.lock_outline,
                                size: 12,
                                color: item.price > 0
                                    ? goldColor
                                    : scheme.outline,
                              ),
                            if (!open) const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                label,
                                style: Theme.of(context).textTheme.labelSmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }(),
      ],
    );
  }
}
