import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zt_sharing_ui/zt_sharing_ui.dart';

import '../data/quests_store.dart';
import '../l10n/l10n.dart';
import '../model/days.dart';
import '../ui/common.dart';
import '../ui/labels.dart';
import 'party_data.dart';
import 'party_model.dart';

// The people, invite, join and code-compare screens are Core's shared ones
// (zt_sharing_ui), so every Zero-Trust app shows the same. Only what is
// about parties lives here.

String _partyName(BuildContext context, String spaceId) =>
    ProviderScope.containerOf(
      context,
      listen: false,
    ).read(partiesProvider).value?.byId(spaceId)?.party?.name ??
    '';

/// Joins a party from an invite link (pasted, scanned or opened).
Future<void> joinParty(BuildContext context, {String? initialLink}) =>
    ZtJoinSpacePage.open(context, initialLink: initialLink);

/// The party tab: every party this account is in, people waiting to join
/// them, and starting or joining one.
class PartyTab extends ConsumerWidget {
  const PartyTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final state = ref.watch(partiesProvider).value;
    final parties = state?.parties ?? const <PartyData>[];
    return RefreshIndicator(
      onRefresh: () async {
        try {
          await ref.read(partyActionsProvider).syncNow();
        } on Object {
          if (context.mounted) showSnack(context, l.partyNeedsInternet);
        }
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
        children: [
          ZtJoinRequestCards(titleOf: (id) => _partyName(context, id)),
          if (parties.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: EmptyState(
                icon: Icons.groups_outlined,
                title: l.tabParty,
                body: l.partyIntro,
              ),
            ),
          for (final p in parties) PartyCard(key: ValueKey(p.spaceId), data: p),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            icon: const Icon(Icons.add),
            label: Text(l.startParty),
            onPressed: () => openCreateParty(context),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
            icon: const Icon(Icons.qr_code_scanner),
            label: Text(l.joinParty),
            onPressed: () => joinParty(context),
          ),
          if (parties.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
              child: Text(
                l.partyIntro,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}

/// A party at a glance: its boss, the boss's hit points and days left.
class PartyCard extends ConsumerWidget {
  const PartyCard({super.key, required this.data, this.compact = false});
  final PartyData data;

  /// On the Today tab: one line under the boss, no board.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final party = data.party;
    if (data.waiting || party == null) {
      return Card(
        child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.hourglass_top)),
          title: Text(l.partyWaiting),
          subtitle: data.entry.joinCode == null
              ? null
              : Text(data.entry.joinCode!),
        ),
      );
    }
    final hunt = data.hunt!;
    final today = ref.watch(todayProvider);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openParty(context, data.spaceId),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: scheme.errorContainer,
                    foregroundColor: scheme.onErrorContainer,
                    child: Icon(
                      party.hasHunt ? bossIcon(party.boss) : Icons.groups,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(party.name, style: t.titleMedium),
                        Text(
                          party.hasHunt
                              ? bossName(l, party.boss)
                              : l.partyCount(data.members.length),
                          style: t.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (party.hasHunt) _DaysLeft(party: party, today: today),
                ],
              ),
              const SizedBox(height: 12),
              HuntBar(hunt: hunt, today: today),
            ],
          ),
        ),
      ),
    );
  }
}

class _DaysLeft extends StatelessWidget {
  const _DaysLeft({required this.party, required this.today});
  final Party party;
  final String today;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (party.end.compareTo(today) < 0) return const SizedBox.shrink();
    final left = daysBetween(today, party.end);
    return Text(
      left == 0 ? l.huntLastDay : l.huntDaysLeft(left + 1),
      style: Theme.of(context).textTheme.labelMedium,
    );
  }
}

/// The boss's hit points, or how the hunt ended.
class HuntBar extends StatelessWidget {
  const HuntBar({
    super.key,
    required this.hunt,
    required this.today,
    this.isAdmin = false,
  });
  final HuntState hunt;
  final String today;

  /// Owners are told they can start the next hunt.
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final party = hunt.party;
    if (!party.hasHunt) return Text(l.noHunt, style: t.bodyMedium);
    if (hunt.defeated) {
      return Row(
        children: [
          const Icon(Icons.emoji_events, color: goldColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l.bossBeaten(
                PartyRules.rewardXp(party.days),
                PartyRules.rewardGold(party.days),
              ),
              style: t.bodyMedium,
            ),
          ),
        ],
      );
    }
    if (hunt.overOn(today)) {
      return Text(
        isAdmin ? l.bossEscaped : l.bossEscapedMember,
        style: t.bodyMedium,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            minHeight: 10,
            value: hunt.ratioLeft,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        const SizedBox(height: 4),
        Text(l.hpLeft(hunt.hpLeft, hunt.hp), style: t.bodySmall),
      ],
    );
  }
}

/// Running hunts, on the Today tab.
class TodayPartyCards extends ConsumerWidget {
  const TodayPartyCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final parties = ref.watch(partiesProvider).value?.parties ?? const [];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final p in parties)
          if (p.party?.runningOn(today) == true && !p.hunt!.defeated)
            PartyCard(key: ValueKey('today-${p.spaceId}'), data: p),
      ],
    );
  }
}

Future<void> openParty(BuildContext context, String spaceId) => Navigator.of(
  context,
).push(MaterialPageRoute<void>(builder: (_) => PartyPage(spaceId: spaceId)));

/// One party: the boss, everyone's damage, and (owners) a new hunt.
class PartyPage extends ConsumerWidget {
  const PartyPage({super.key, required this.spaceId});
  final String spaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final data = ref.watch(partiesProvider).value?.byId(spaceId);
    final party = data?.party;
    final today = ref.watch(todayProvider);
    if (data == null || party == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l.partyWaiting)),
      );
    }
    final hunt = data.hunt!;
    final canStart = data.isAdmin && (!party.hasHunt || hunt.overOn(today));
    return Scaffold(
      appBar: AppBar(
        title: Text(party.name),
        actions: [
          IconButton(
            tooltip: l.partyPeople,
            icon: const Icon(Icons.group_outlined),
            onPressed: () => ZtSpacePage.open(
              context,
              spaceId: spaceId,
              title: party.name,
              description: l.partyE2e,
            ),
          ),
          if (data.isAdmin)
            IconButton(
              tooltip: l.renameParty,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _rename(context, ref, data),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (party.hasHunt) ...[
                    Icon(
                      bossIcon(party.boss),
                      size: 56,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      bossName(l, party.boss),
                      style: t.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    Center(
                      child: _DaysLeft(party: party, today: today),
                    ),
                    const SizedBox(height: 12),
                  ],
                  HuntBar(hunt: hunt, today: today, isAdmin: data.isAdmin),
                  if (party.hasHunt && !hunt.overOn(today)) ...[
                    const SizedBox(height: 8),
                    Text(
                      l.partyRewardNote(
                        PartyRules.rewardXp(party.days),
                        PartyRules.rewardGold(party.days),
                      ),
                      style: t.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (canStart)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                icon: const Icon(Icons.sports_martial_arts),
                label: Text(l.newHunt),
                onPressed: () => _newHunt(context, ref, data),
              ),
            ),
          for (final s in hunt.board)
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: heroColor(
                    s.member?.color ?? 'teal',
                  ).withValues(alpha: 0.15),
                  foregroundColor: heroColor(s.member?.color ?? 'teal'),
                  child: Icon(emblemIcon(s.member?.emblem ?? 'shield')),
                ),
                title: Text(s.name),
                subtitle: Text(
                  s.member == null
                      ? l.partyNoHitsYet
                      : '${l.partyLevel(s.member!.level)} · '
                            '${l.partyHits(s.member!.dailies, s.member!.tasks)}',
                ),
                trailing: Text(l.partyDamage(s.damage), style: t.labelLarge),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Text(l.partyE2e, style: t.bodySmall),
          ),
        ],
      ),
    );
  }

  Future<void> _newHunt(
    BuildContext context,
    WidgetRef ref,
    PartyData data,
  ) async {
    final l = context.l10n;
    final days = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l.newHunt),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(l.newHuntBody),
          ),
          for (final d in PartyRules.lengths)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, d),
              child: Text(l.daysCount(d)),
            ),
        ],
      ),
    );
    if (days == null) return;
    try {
      await ref
          .read(partyActionsProvider)
          .newHunt(data, day: ref.read(todayProvider), days: days);
    } on Object {
      if (context.mounted) showSnack(context, l.partyNeedsInternet);
    }
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    PartyData data,
  ) async {
    final l = context.l10n;
    final c = TextEditingController(text: data.party!.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.renameParty),
        content: TextField(
          controller: c,
          autofocus: true,
          maxLength: 40,
          textCapitalization: TextCapitalization.words,
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
    c.dispose();
    if (name == null || name.isEmpty) return;
    try {
      await ref.read(partyActionsProvider).rename(data, name);
    } on Object {
      if (context.mounted) showSnack(context, l.partyNeedsInternet);
    }
  }
}

Future<void> openCreateParty(BuildContext context) => Navigator.of(
  context,
).push(MaterialPageRoute<void>(builder: (_) => const CreatePartyPage()));

/// A new party: its name, how strong its bosses are, the first hunt's
/// length. Then the invite page opens.
class CreatePartyPage extends ConsumerStatefulWidget {
  const CreatePartyPage({super.key});

  @override
  ConsumerState<CreatePartyPage> createState() => _CreatePartyPageState();
}

class _CreatePartyPageState extends ConsumerState<CreatePartyPage> {
  final _name = TextEditingController();
  PartyDifficulty _difficulty = PartyDifficulty.normal;
  int _days = 7;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String _diffName(AppL10n l, PartyDifficulty d) => switch (d) {
    PartyDifficulty.easy => l.diffEasy,
    PartyDifficulty.normal => l.diffNormal,
    PartyDifficulty.hard => l.diffHard,
  };

  Future<void> _create() async {
    final l = context.l10n;
    final partyName = _name.text.trim();
    if (partyName.isEmpty) return;
    final myName = await ztAskSharingName(context, ref, title: l.startParty);
    if (myName == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final spaceId = await ref
          .read(partyActionsProvider)
          .create(
            Party(name: partyName, difficulty: _difficulty),
            myName: myName,
            day: ref.read(todayProvider),
            days: _days,
          );
      if (!mounted) return;
      Navigator.pop(context);
      await ZtSpacePage.open(
        context,
        spaceId: spaceId,
        title: partyName,
        description: l.partyE2e,
        inviteNow: true,
      );
    } on Object {
      if (mounted) {
        setState(() => _busy = false);
        showSnack(context, l.partyNeedsInternet);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(l.startParty)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l.partyIntro),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            maxLength: 40,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l.partyNameLabel,
              hintText: l.partyNameHint,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Text(l.partyDifficulty, style: t.labelLarge),
          Wrap(
            spacing: 8,
            children: [
              for (final d in PartyDifficulty.values)
                ChoiceChip(
                  label: Text(_diffName(l, d)),
                  selected: d == _difficulty,
                  onSelected: (_) => setState(() => _difficulty = d),
                ),
            ],
          ),
          Text(
            l.diffHint(_difficulty.hpPerMemberDay, PartyRules.dailyHit),
            style: t.bodySmall,
          ),
          const SizedBox(height: 16),
          Text(l.huntLength, style: t.labelLarge),
          Wrap(
            spacing: 8,
            children: [
              for (final d in PartyRules.lengths)
                ChoiceChip(
                  label: Text(l.daysCount(d)),
                  selected: d == _days,
                  onSelected: (_) => setState(() => _days = d),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(l.partyE2e, style: t.bodySmall),
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            onPressed: _busy || _name.text.trim().isEmpty ? null : _create,
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l.createParty),
          ),
        ],
      ),
    );
  }
}
