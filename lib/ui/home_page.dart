import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/quests_store.dart';
import '../l10n/l10n.dart';
import '../party/party_pages.dart';
import 'epics_tab.dart';
import 'goal_wizard.dart';
import 'goals_tab.dart';
import 'hero_tab.dart';
import 'settings_page.dart';
import 'today_tab.dart';

/// Today, Epics, Party, Goals and Hero, with Settings in the app bar.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final goals = ref.watch(goalsProvider).value ?? const [];
    final active = goals.where((g) => !g.archived).toList();
    final titles = [l.tabToday, l.tabEpics, l.tabParty, l.tabGoals, l.tabHero];
    final Widget? fab = switch (_tab) {
      1 when active.isNotEmpty => FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(l.ownEpicTitle),
        onPressed: () => openOwnEpic(context, active),
      ),
      3 => FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(l.newGoal),
        onPressed: () => openGoalWizard(context),
      ),
      _ => null,
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(_tab == 0 ? 'ZT Quests' : titles[_tab]),
        actions: [
          IconButton(
            tooltip: l.settings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const QuestsSettingsPage(),
              ),
            ),
          ),
        ],
      ),
      body: switch (_tab) {
        0 => TodayTab(onOpenHero: () => setState(() => _tab = 4)),
        1 => const EpicsTab(),
        2 => const PartyTab(),
        3 => const GoalsTab(),
        _ => const HeroTab(),
      },
      floatingActionButton: fab,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.today_outlined),
            selectedIcon: const Icon(Icons.today),
            label: l.tabToday,
          ),
          NavigationDestination(
            icon: const Icon(Icons.landscape_outlined),
            selectedIcon: const Icon(Icons.landscape),
            label: l.tabEpics,
          ),
          NavigationDestination(
            icon: const Icon(Icons.groups_outlined),
            selectedIcon: const Icon(Icons.groups),
            label: l.tabParty,
          ),
          NavigationDestination(
            icon: const Icon(Icons.flag_outlined),
            selectedIcon: const Icon(Icons.flag),
            label: l.tabGoals,
          ),
          NavigationDestination(
            icon: const Icon(Icons.shield_outlined),
            selectedIcon: const Icon(Icons.shield),
            label: l.tabHero,
          ),
        ],
      ),
    );
  }
}
