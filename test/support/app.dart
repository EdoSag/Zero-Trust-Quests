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
import 'package:zerotrust_quests/notify/daily_reminder.dart';

/// Keeps everything in memory, in place of the encrypted store.
class MemoryRepository extends QuestsRepository {
  MemoryRepository(
    super.ref, {
    List<Goal> goals = const [],
    List<Quest> quests = const [],
  }) {
    for (final g in goals) {
      _goals[g.id] = g;
    }
    for (final q in quests) {
      _quests[q.id] = q;
    }
  }

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
  Locale locale = ZtLanguages.english,
  String day = '2026-11-17',
}) {
  return ProviderScope(
    overrides: [
      ztAppConfigProvider.overrideWithValue(questsAppConfig),
      ztPreferencesStoreProvider.overrideWithValue(InMemoryPreferencesStore()),
      healthSourceProvider.overrideWithValue(const NoHealthSource()),
      dailyReminderProvider.overrideWithValue(NoopDailyReminder()),
      todayProvider.overrideWith(() => _FixedDay(day)),
      questsRepositoryProvider.overrideWith(
        (ref) => repo = MemoryRepository(ref, goals: goals, quests: quests),
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
