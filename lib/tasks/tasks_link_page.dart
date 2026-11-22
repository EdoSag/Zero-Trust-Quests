import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/quests_store.dart';
import '../engine/hero.dart';
import '../l10n/l10n.dart';
import '../ui/common.dart';
import 'linked_tasks.dart';
import 'tasks_bridge.dart';

/// Settings row: which ZT Tasks lists earn XP here.
class TasksLinkTile extends ConsumerWidget {
  const TasksLinkTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final link = ref.watch(tasksLinkProvider).value ?? const TasksLink();
    return ListTile(
      leading: const Icon(Icons.checklist),
      title: Text(l.tasksLinkTitle),
      subtitle: Text(
        link.isOn ? l.tasksLinkOn(link.lists.length) : l.tasksLinkOff,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const TasksLinkPage())),
    );
  }
}

class TasksLinkPage extends ConsumerWidget {
  const TasksLinkPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final link = ref.watch(tasksLinkProvider).value ?? const TasksLink();
    final snapshot = ref.watch(tasksSnapshotProvider);
    final lists = snapshot.value?.lists ?? const <LinkedTaskList>[];
    final refreshOk = snapshot.value?.refreshOk;
    final onlyDefault =
        lists.length == 1 &&
        lists.single.name.isEmpty &&
        !(snapshot.value?.tasks.isNotEmpty ?? false);
    return Scaffold(
      appBar: AppBar(title: Text(l.tasksLinkTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              l.tasksLinkBody(
                TaskRewards.xpFor('low'),
                TaskRewards.xpFor('critical'),
                HeroStats.tasksPerDay,
              ),
            ),
          ),
          if (snapshot.isLoading || (refreshOk == null && lists.isEmpty))
            ListTile(
              leading: const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              title: Text(l.tasksLoading),
            )
          else if (snapshot.hasError && lists.isEmpty)
            ListTile(
              leading: const Icon(Icons.cloud_off),
              title: Text(l.tasksOffline),
            )
          else ...[
            if (refreshOk == false)
              ListTile(
                leading: const Icon(Icons.cloud_off),
                title: Text(l.tasksOffline),
              ),
            if (onlyDefault && refreshOk == true)
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(l.tasksNone),
              ),
            for (final list in lists)
              SwitchListTile(
                secondary: const Icon(Icons.list_alt),
                title: Text(list.name.isEmpty ? l.tasksDefaultList : list.name),
                value: link.lists.containsKey(list.id),
                onChanged: (on) async {
                  try {
                    await ref
                        .read(questsRepositoryProvider)
                        .saveTasksLink(
                          link.withList(
                            list.id,
                            on: on,
                            day: ref.read(todayProvider),
                          ),
                        );
                  } on Object {
                    if (context.mounted) showSnack(context, l.couldNotLoad);
                  }
                },
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Text(
                l.tasksSharedNote,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
