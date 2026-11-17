import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:zero_trust_core/zero_trust_core.dart';

import '../engine/engine.dart';
import '../engine/hero.dart';
import '../model/days.dart';
import '../model/goal.dart';
import '../model/quest.dart';

/// Goals, quests, purchases and the hero are items of the Quests app,
/// sealed with its own key (`app = 'quests'`): `kind` goal, quest,
/// purchase and hero. No database change.
final goalsCollection = ZtCollection<Goal>(
  kind: 'goal',
  fromJson: (id, json, _) => Goal.fromJson(id, json),
  toJson: (g) => g.toJson(),
  idOf: (g) => g.id,
);

final questsCollection = ZtCollection<Quest>(
  kind: 'quest',
  fromJson: (id, json, _) => Quest.fromJson(id, json),
  toJson: (q) => q.toJson(),
  idOf: (q) => q.id,
);

final purchasesCollection = ZtCollection<Purchase>(
  kind: 'purchase',
  fromJson: (id, json, _) => Purchase.fromJson(id, json),
  toJson: (p) => p.toJson(),
  idOf: (p) => p.id,
);

const heroItemId = 'hero';

final heroCollection = ZtCollection<HeroLook>(
  kind: 'hero',
  fromJson: (_, json, _) => HeroLook.fromJson(json),
  toJson: (h) => h.toJson(),
  idOf: (_) => heroItemId,
);

Stream<List<T>> _watch<T>(Ref ref, ZtCollection<T> c) async* {
  final store = await ref.watch(ztLocalStoreProvider.future);
  if (store is ZtLocalStore) {
    yield* c.watch(store);
  } else {
    yield await c.list(store);
  }
}

final goalsProvider = StreamProvider<List<Goal>>((ref) {
  return _watch(
    ref,
    goalsCollection,
  ).map((l) => [...l]..sort((a, b) => a.createdDay.compareTo(b.createdDay)));
});

final questsProvider = StreamProvider<List<Quest>>(
  (ref) => _watch(ref, questsCollection),
);

final purchasesProvider = StreamProvider<List<Purchase>>(
  (ref) => _watch(ref, purchasesCollection),
);

final heroLookProvider = StreamProvider<HeroLook>((ref) {
  return _watch(
    ref,
    heroCollection,
  ).map((l) => l.isEmpty ? const HeroLook() : l.first);
});

/// Today's date key. Moves on at midnight and when the app comes back.
final todayProvider = NotifierProvider<TodayNotifier, String>(
  TodayNotifier.new,
);

class TodayNotifier extends Notifier<String> {
  Timer? _timer;

  @override
  String build() {
    ref.onDispose(() => _timer?.cancel());
    _arm();
    return today();
  }

  void _arm() {
    _timer?.cancel();
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    _timer = Timer(midnight.difference(now) + const Duration(seconds: 1), () {
      refresh();
    });
  }

  void refresh() {
    final t = today();
    if (t != state) state = t;
    _arm();
  }
}

final heroStatsProvider = Provider<HeroStats>((ref) {
  final quests = ref.watch(questsProvider).value ?? const <Quest>[];
  final purchases = ref.watch(purchasesProvider).value ?? const <Purchase>[];
  return HeroStats.compute(quests, purchases, ref.watch(todayProvider));
});

final questsRepositoryProvider = Provider<QuestsRepository>(
  (ref) => QuestsRepository(ref),
);

/// Saves and deletes through the shared sync controller, so every change is
/// encrypted, stored locally and sent to the account's other devices.
class QuestsRepository {
  QuestsRepository(this._ref);
  final Ref _ref;

  static const _uuid = Uuid();
  static String newId() => _uuid.v4();

  SyncController get _sync => _ref.read(ztSyncControllerProvider.notifier);
  Future<LocalItemStore> get _store => _ref.read(ztLocalStoreProvider.future);

  Future<List<Goal>> allGoals() async => goalsCollection.list(await _store);
  Future<List<Quest>> allQuests() async => questsCollection.list(await _store);

  Future<void> saveGoal(Goal g) async =>
      goalsCollection.save(_sync, await _store, g);

  Future<void> saveQuest(Quest q) async =>
      questsCollection.save(_sync, await _store, q);

  Future<void> deleteQuest(String id) => questsCollection.delete(_sync, id);

  Future<void> savePurchase(Purchase p) async =>
      purchasesCollection.save(_sync, await _store, p);

  Future<void> saveHero(HeroLook h) async =>
      heroCollection.save(_sync, await _store, h);

  /// Deletes a goal and every quest made for it. Their XP and gold go too.
  Future<void> deleteGoal(String id) async {
    for (final q in await allQuests()) {
      if (q.goalId == id) await deleteQuest(q.id);
    }
    await goalsCollection.delete(_sync, id);
  }

  /// The last plan, so two quick calls don't make the same quest twice.
  Future<void> _turn = Future.value();

  /// Makes today's missing daily quests (and swaps for declined ones).
  Future<List<Quest>> planDay(String day) {
    final result = _turn.then((_) async {
      final made = QuestEngine.plan(await allGoals(), await allQuests(), day);
      for (final q in made) {
        await saveQuest(q);
      }
      return made;
    });
    _turn = result.then<void>((_) {}, onError: (_) {});
    return result;
  }
}
