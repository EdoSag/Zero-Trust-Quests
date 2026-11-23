import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zero_trust_core/zero_trust_core.dart';
import 'package:zerotrust_quests/app/quests_config.dart';
import 'package:zerotrust_quests/data/quests_store.dart';
import 'package:zerotrust_quests/health/health_source.dart';
import 'package:zerotrust_quests/l10n/l10n.dart';
import 'package:zerotrust_quests/model/goal.dart';
import 'package:zerotrust_quests/model/quest.dart';
import 'package:zerotrust_quests/model/reward.dart';
import 'package:zerotrust_quests/notify/daily_reminder.dart';
import 'package:zerotrust_quests/party/party_data.dart';
import 'package:zerotrust_quests/tasks/linked_tasks.dart';

/// Keeps everything in memory, in place of the encrypted store.
class MemoryRepository extends QuestsRepository {
  MemoryRepository(
    super.ref, {
    List<Goal> goals = const [],
    List<Quest> quests = const [],
    List<Reward> rewards = const [],
    this.tasksLink = const TasksLink(),
  }) {
    for (final g in goals) {
      _goals[g.id] = g;
    }
    for (final q in quests) {
      _quests[q.id] = q;
    }
    for (final r in rewards) {
      _rewards[r.id] = r;
    }
  }

  final _rewards = <String, Reward>{};
  TasksLink tasksLink;
  List<Reward> get rewards => _rewards.values.toList();

  final _goals = <String, Goal>{};
  final _quests = <String, Quest>{};
  final purchases = <Purchase>[];
  HeroLook hero = const HeroLook();
  final _changes = StreamController<void>.broadcast();

  List<Goal> get goals => _goals.values.toList();
  List<Quest> get quests => _quests.values.toList();

  Stream<List<T>> _watch<T>(List<T> Function() read) async* {
    yield read();
    yield* _changes.stream.map((_) => read());
  }

  Stream<List<Goal>> watchGoals() => _watch(() => goals);
  Stream<List<Quest>> watchQuests() => _watch(() => quests);
  Stream<List<Purchase>> watchPurchases() => _watch(() => [...purchases]);
  Stream<HeroLook> watchHero() => _watch(() => [hero]).map((l) => l.first);
  Stream<List<Reward>> watchRewards() => _watch(() => rewards);
  Stream<TasksLink> watchTasksLink() =>
      _watch(() => [tasksLink]).map((l) => l.first);

  @override
  Future<List<Reward>> allRewards() async => rewards;

  @override
  Future<void> saveReward(Reward r) async {
    _rewards[r.id] = r;
    _changes.add(null);
  }

  @override
  Future<void> deleteReward(String id) async {
    _rewards.remove(id);
    _changes.add(null);
  }

  @override
  Future<void> saveTasksLink(TasksLink link) async {
    tasksLink = link;
    _changes.add(null);
  }

  @override
  Future<List<Goal>> allGoals() async => goals;
  @override
  Future<List<Quest>> allQuests() async => quests;

  @override
  Future<void> saveGoal(Goal g) async {
    _goals[g.id] = g;
    _changes.add(null);
  }

  @override
  Future<void> saveQuest(Quest q) async {
    _quests[q.id] = q;
    _changes.add(null);
  }

  @override
  Future<void> deleteQuest(String id) async {
    _quests.remove(id);
    _changes.add(null);
  }

  @override
  Future<void> deleteGoal(String id) async {
    _quests.removeWhere((_, q) => q.goalId == id);
    _goals.remove(id);
    _changes.add(null);
  }

  @override
  Future<void> savePurchase(Purchase p) async {
    purchases.add(p);
    _changes.add(null);
  }

  @override
  Future<void> saveHero(HeroLook h) async {
    hero = h;
    _changes.add(null);
  }
}

late MemoryRepository repo;

Widget app(
  Widget home, {
  List<Goal> goals = const [],
  List<Quest> quests = const [],
  List<Reward> rewards = const [],
  TasksLink tasksLink = const TasksLink(),
  Locale locale = ZtLanguages.english,
  String day = '2026-11-17',
  HealthSource health = const NoHealthSource(),
  PreferencesStore? prefs,
  List overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      ...overrides.cast(),
      ztAppConfigProvider.overrideWithValue(questsAppConfig),
      ztPreferencesStoreProvider.overrideWithValue(
        prefs ?? InMemoryPreferencesStore(),
      ),
      healthSourceProvider.overrideWithValue(health),
      dailyReminderProvider.overrideWithValue(NoopDailyReminder()),
      todayProvider.overrideWith(() => _FixedDay(day)),
      questsRepositoryProvider.overrideWith(
        (ref) => repo = MemoryRepository(
          ref,
          goals: goals,
          quests: quests,
          rewards: rewards,
          tasksLink: tasksLink,
        ),
      ),
      rewardsProvider.overrideWith(
        (ref) => (ref.watch(questsRepositoryProvider) as MemoryRepository)
            .watchRewards(),
      ),
      tasksLinkProvider.overrideWith(
        (ref) => (ref.watch(questsRepositoryProvider) as MemoryRepository)
            .watchTasksLink(),
      ),
      partiesProvider.overrideWith(
        (ref) async => const PartiesState(ready: true, loading: false),
      ),
      goalsProvider.overrideWith(
        (ref) => (ref.watch(questsRepositoryProvider) as MemoryRepository)
            .watchGoals(),
      ),
      questsProvider.overrideWith(
        (ref) => (ref.watch(questsRepositoryProvider) as MemoryRepository)
            .watchQuests(),
      ),
      purchasesProvider.overrideWith(
        (ref) => (ref.watch(questsRepositoryProvider) as MemoryRepository)
            .watchPurchases(),
      ),
      heroLookProvider.overrideWith(
        (ref) => (ref.watch(questsRepositoryProvider) as MemoryRepository)
            .watchHero(),
      ),
    ],
    child: MaterialApp(
      // The suite's real theme: its full-width buttons break rows that a
      // plain theme lets through.
      theme: ZtTheme.light(accent: questsAppConfig.accent),
      locale: locale,
      supportedLocales: ZtLanguages.supported,
      localizationsDelegates: const [
        AppL10n.delegate,
        ...ZtLanguages.delegates,
      ],
      home: home,
    ),
  );
}

class _FixedDay extends TodayNotifier {
  _FixedDay(this.day);
  final String day;
  @override
  String build() => day;
  @override
  void refresh() {}
}
