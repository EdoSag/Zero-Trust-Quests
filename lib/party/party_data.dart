import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zero_trust_core/zero_trust_core.dart';

import '../data/quests_store.dart';
import '../model/quest.dart';
import '../model/reward.dart';
import 'party_model.dart';

/// Only a party's owners set its name and hunts; each member's numbers can
/// be written only by that member (every phone checks the signed author).
const SpacePolicy questsSpacePolicy = SpacePolicy(
  adminOnlyKinds: {Party.kind},
  ownedPrefixes: {PartyMember.prefix},
);

/// Bumped after every local party write, so screens update at once even
/// offline.
final partyRevisionProvider = NotifierProvider<PartyRevision, int>(
  PartyRevision.new,
);

class PartyRevision extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}

/// One party as the screens show it.
class PartyData {
  PartyData({
    required this.entry,
    required this.myUserId,
    this.party,
    this.members = const {},
    this.progress = const {},
  });

  final SpaceEntry entry;
  final String myUserId;

  /// Null until the party's details have arrived (just joined).
  final Party? party;

  /// Current members, user id to name.
  final Map<String, String> members;
  final Map<String, PartyMember> progress;

  String get spaceId => entry.info.id;
  bool get isAdmin => entry.info.myRole == SpaceRole.admin;

  /// Joined, but an owner hasn't confirmed the codes yet.
  bool get waiting => entry.space == null || party == null;

  HuntState? get hunt => party == null
      ? null
      : HuntState.of(party: party!, members: members, progress: progress);
}

class PartiesState {
  const PartiesState({
    this.parties = const [],
    this.ready = false,
    this.loading = true,
    this.error,
  });

  final List<PartyData> parties;
  final bool ready;
  final bool loading;
  final Object? error;

  PartyData? byId(String spaceId) {
    for (final p in parties) {
      if (p.spaceId == spaceId) return p;
    }
    return null;
  }
}

Future<PartyData> readParty(SpaceEntry entry, String myUserId) async {
  final space = entry.space;
  if (space == null) return PartyData(entry: entry, myUserId: myUserId);
  Party? party;
  final progress = <String, PartyMember>{};
  for (final item in await space.store.all()) {
    if (item.deleted) continue;
    if (item.itemId == Party.itemId && item.json != null) {
      party = Party.fromJson(item.json!);
    } else if (PartyMember.fromJson(item.itemId, item.json) case final m?) {
      progress[m.userId] = m;
    }
  }
  final members = {for (final m in space.members) m.userId: m.name};
  return PartyData(
    entry: entry,
    myUserId: myUserId,
    party: party,
    members: members,
    // People who left don't stay on the board.
    progress: {
      for (final e in progress.entries)
        if (members.containsKey(e.key)) e.key: e.value,
    },
  );
}

/// Every party this account is in, by name.
final partiesProvider = FutureProvider<PartiesState>((ref) async {
  ref.watch(partyRevisionProvider);
  final spaces = ref.watch(ztSpacesProvider);
  final myUserId = ref.watch(accountServiceProvider).currentUserId ?? '';
  final out = <PartyData>[
    for (final e in spaces.entries) await readParty(e, myUserId),
  ]..sort((a, b) => (a.party?.name ?? '').compareTo(b.party?.name ?? ''));
  return PartiesState(
    parties: out,
    ready: spaces.ready,
    loading: spaces.loading,
    error: spaces.error,
  );
});

final partyActionsProvider = Provider<PartyActions>(PartyActions.new);

class PartyActions {
  PartyActions(this._ref);
  final Ref _ref;

  SpacesController get _spaces => _ref.read(ztSpacesProvider.notifier);
  void _bump() => _ref.read(partyRevisionProvider.notifier).bump();

  /// Starts a party with this account as its owner, and its first hunt.
  Future<String> create(
    Party party, {
    required String myName,
    required String day,
    required int days,
  }) async {
    final space = await _spaces.create(myName: myName);
    await _spaces.save(
      space.id,
      Party.itemId,
      party.nextHunt(day, days, salt: space.id).toJson(),
    );
    _bump();
    unawaited(publishAll());
    return space.id;
  }

  /// A new hunt (owners only), once the last one is over.
  Future<void> newHunt(PartyData p, {required String day, required int days}) {
    return _save(p.spaceId, p.party!.nextHunt(day, days, salt: p.spaceId));
  }

  Future<void> rename(PartyData p, String name) =>
      _save(p.spaceId, p.party!.copyWith(name: name));

  Future<void> _save(String spaceId, Party party) async {
    await _spaces.save(spaceId, Party.itemId, party.toJson());
    _bump();
    unawaited(publishAll());
  }

  Future<void> syncNow() async {
    await _spaces.refresh();
    await _spaces.syncAll();
    _bump();
  }

  Future<void>? _publishing;
  bool _again = false;

  /// Shares this account's damage with every party whose hunt is on (and
  /// a few days after, so late quests still count), and takes the reward
  /// of every boss this account helped beat. Only writes what changed.
  Future<void> publishAll() {
    if (_publishing != null) {
      _again = true;
      return _publishing!;
    }
    return _publishing = _publish().whenComplete(() {
      _publishing = null;
      if (_again) {
        _again = false;
        publishAll();
      }
    });
  }

  Future<void> _publish() async {
    final state = await _ref.read(partiesProvider.future);
    final repo = _ref.read(questsRepositoryProvider);
    final today = _ref.read(todayProvider);
    final quests = await repo.allQuests();
    final rewards = await repo.allRewards();
    final stats = _ref.read(heroStatsProvider);
    final look = _ref.read(heroLookProvider).value ?? const HeroLook();
    final have = {for (final r in rewards) r.id};
    var wrote = false;
    for (final p in state.parties) {
      final party = p.party;
      if (party == null || p.entry.space == null) continue;
      if (!p.members.containsKey(p.myUserId)) continue;
      var mine = p.progress[p.myUserId];
      if (party.scoringOn(today)) {
        final now = PartyMember.compute(
          userId: p.myUserId,
          party: party,
          quests: quests,
          rewards: rewards,
          stats: stats,
          look: look,
        );
        if (!now.sameAs(mine)) {
          try {
            await _spaces.save(
              p.spaceId,
              PartyMember.itemIdFor(p.myUserId),
              now.toJson(),
            );
            wrote = true;
          } on Object {
            // Locked or left meanwhile: the next change tries again.
          }
        }
        mine = now;
      }
      // Beaten: everyone who hit it takes the reward, once.
      final hunt = p.hunt;
      if (hunt != null &&
          hunt.defeated &&
          mine != null &&
          mine.round == party.round &&
          mine.damage > 0) {
        final reward = partyReward(
          spaceId: p.spaceId,
          party: party,
          day: today,
        );
        if (!have.contains(reward.id)) {
          await repo.saveReward(reward);
          have.add(reward.id);
        }
      }
    }
    if (wrote) _bump();
  }
}

/// Keeps this account's party damage up to date while unlocked: when its
/// quests or rewards change and when parties arrive or change. Watched by
/// the main screen.
final partyPublisherProvider = Provider<void>((ref) {
  Timer? timer;
  void schedule() {
    timer?.cancel();
    timer = Timer(const Duration(seconds: 3), () {
      ref.read(partyActionsProvider).publishAll().ignore();
    });
  }

  ref.listen<AsyncValue<List<Quest>>>(questsProvider, (_, _) => schedule());
  ref.listen<AsyncValue<List<Reward>>>(rewardsProvider, (_, _) => schedule());
  ref.listen(heroLookProvider, (_, _) => schedule());
  ref.listen(partiesProvider, (prev, next) {
    final now = next.value?.parties;
    if (now == null) return;
    String key(List<PartyData> l) => [
      for (final p in l)
        '${p.spaceId}:${p.members.length}:${p.party?.toJson()}:'
            '${p.hunt?.defeated}',
    ].join('|');
    final before = prev?.value?.parties;
    if (before == null || key(before) != key(now)) schedule();
  });
  ref.onDispose(() => timer?.cancel());
});
