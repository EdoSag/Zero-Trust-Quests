import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../model/days.dart';
import '../model/reward.dart';

/// A ZT Tasks task, as Quests reads it from the account (ZT Tasks' own
/// JSON: tasks are its items without a `kind`).
@immutable
class LinkedTask {
  const LinkedTask({
    required this.id,
    required this.title,
    this.listId = LinkedTaskList.defaultId,
    this.priority = 'medium',
    this.completed = false,
    this.completedAt,
    this.dueDay,
    this.repeats = false,
    this.deleted = false,
  });

  final String id;
  final String title;
  final String listId;

  /// `critical`, `high`, `medium` or `low`.
  final String priority;
  final bool completed;
  final DateTime? completedAt;

  /// The due date's day (`yyyy-MM-dd`), or null.
  final String? dueDay;

  /// A repeating task. ZT Tasks rolls it on to its next due date when it is
  /// ticked off (it stays not completed), so a round done shows as the due
  /// date moving on.
  final bool repeats;

  /// In ZT Tasks' trash.
  final bool deleted;

  static LinkedTask? fromItem(String id, Map<String, Object?>? json) {
    if (json == null || json['kind'] != null) return null;
    final title = json['title'];
    if (title is! String) return null;
    DateTime? date(Object? v) =>
        v is String ? DateTime.tryParse(v)?.toLocal() : null;
    final due = date(json['dueDate']);
    final list = json['listId'];
    return LinkedTask(
      id: id,
      title: title,
      listId: list is String && list.isNotEmpty
          ? list
          : LinkedTaskList.defaultId,
      priority: (json['priority'] as String?) ?? 'medium',
      completed: json['isCompleted'] == true,
      completedAt: date(json['completedAt']),
      dueDay: due == null ? null : dayKey(due),
      repeats: json['recurrence'] is Map,
      deleted: json['deletedAt'] != null,
    );
  }
}

/// A ZT Tasks list ("My Tasks", "Work"). Tasks without a list are in the
/// default one, which exists even before it is renamed (and stored).
@immutable
class LinkedTaskList {
  const LinkedTaskList({required this.id, required this.name});

  static const defaultId = 'default';

  final String id;

  /// Empty for the default list that was never renamed (shown as "My
  /// Tasks" in the app's language).
  final String name;

  static LinkedTaskList? fromItem(String id, Map<String, Object?>? json) {
    if (json == null || json['kind'] != 'task_list') return null;
    return LinkedTaskList(id: id, name: (json['name'] as String?) ?? '');
  }
}

/// Everything Quests knows of ZT Tasks right now.
@immutable
class TasksSnapshot {
  const TasksSnapshot({
    this.tasks = const [],
    this.lists = const [],
    this.refreshOk,
  });

  final List<LinkedTask> tasks;

  /// The account's own lists, default first. Shared lists live in their
  /// own shared spaces and aren't read.
  final List<LinkedTaskList> lists;

  /// How the last pull went: null while the first runs, then true or false
  /// (offline).
  final bool? refreshOk;

  static TasksSnapshot fromItems(
    Iterable<(String, Map<String, Object?>?)> items, {
    bool? refreshOk,
  }) {
    final tasks = <LinkedTask>[];
    final lists = <String, LinkedTaskList>{};
    for (final (id, json) in items) {
      if (LinkedTask.fromItem(id, json) case final t?) tasks.add(t);
      if (LinkedTaskList.fromItem(id, json) case final l?) lists[id] = l;
    }
    final def =
        lists.remove(LinkedTaskList.defaultId) ??
        const LinkedTaskList(id: LinkedTaskList.defaultId, name: '');
    final others = lists.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return TasksSnapshot(
      tasks: tasks,
      lists: [def, ...others],
      refreshOk: refreshOk,
    );
  }
}

/// Which ZT Tasks lists count in Quests, each with the day it was linked:
/// tasks ticked off before then don't earn anything. Synced (item
/// [itemId]), so every phone of the account rewards the same tasks.
@immutable
class TasksLink {
  const TasksLink({this.lists = const {}});

  static const itemId = 'tasks-link';

  /// List id -> the day it was linked.
  final Map<String, String> lists;

  bool get isOn => lists.isNotEmpty;

  TasksLink withList(String listId, {required bool on, required String day}) =>
      TasksLink(
        lists: {
          for (final e in lists.entries)
            if (e.key != listId) e.key: e.value,
          if (on) listId: lists[listId] ?? day,
        },
      );

  Map<String, Object?> toJson() => {'lists': lists};

  static TasksLink fromJson(Map<String, Object?> j) => TasksLink(
    lists: {
      for (final e in ((j['lists'] as Map?) ?? const {}).entries)
        if (e.value is String) '${e.key}': e.value as String,
    },
  );
}

/// What to save after looking at ZT Tasks.
@immutable
class TaskRewardPlan {
  const TaskRewardPlan({
    this.save = const [],
    this.delete = const [],
    this.seen = const {},
  });

  final List<Reward> save;

  /// Rewards of tasks that were ticked back on.
  final List<String> delete;

  /// Each repeating task's due day now, to notice the next round.
  final Map<String, String> seen;

  bool get isEmpty => save.isEmpty && delete.isEmpty;
}

/// Turns tasks ticked off in the linked lists into rewards.
abstract final class TaskRewards {
  static int xpFor(String priority) => switch (priority) {
    'critical' => 12,
    'high' => 10,
    'low' => 5,
    _ => 8,
  };

  static int goldFor(int xp) => math.max(1, xp ~/ 4);

  /// A one-off task's reward id.
  static String idFor(String taskId) => 'task-$taskId';

  /// One round of a repeating task, due on [dueDay].
  static String roundIdFor(String taskId, String dueDay) =>
      'task-$taskId-$dueDay';

  /// [existing] are the task rewards saved so far; [seen] each repeating
  /// task's due day when last looked at, on this phone.
  static TaskRewardPlan plan({
    required List<LinkedTask> tasks,
    required TasksLink link,
    required Set<String> existing,
    required Map<String, String> seen,
    required String today,
  }) {
    final save = <Reward>[];
    final delete = <String>[];
    final nextSeen = <String, String>{};
    void add(LinkedTask t, String id, String day) {
      if (existing.contains(id)) return;
      final xp = xpFor(t.priority);
      save.add(
        Reward(
          id: id,
          source: RewardSource.task,
          day: day,
          xp: xp,
          gold: goldFor(xp),
          title: t.title,
          ref: t.id,
        ),
      );
    }

    for (final t in tasks) {
      final since = link.lists[t.listId];
      bool counts(String day) =>
          since != null &&
          day.compareTo(since) >= 0 &&
          day.compareTo(today) <= 0;
      if (t.completed) {
        final done = t.completedAt == null ? null : dayKey(t.completedAt!);
        if (done == null || !counts(done)) continue;
        // A repeating task whose repeats ended is ticked off like any task.
        add(
          t,
          t.repeats ? roundIdFor(t.id, t.dueDay ?? done) : idFor(t.id),
          done,
        );
        continue;
      }
      if (!t.repeats) {
        // Ticked back on: it wasn't done after all.
        if (!t.deleted && existing.contains(idFor(t.id))) {
          delete.add(idFor(t.id));
        }
        continue;
      }
      final due = t.dueDay;
      if (due == null || since == null || t.deleted) continue;
      nextSeen[t.id] = due;
      final before = seen[t.id];
      // Rolled on to a later date: the round due then (today or earlier)
      // was done. Seen today, so it counts from the day the list was
      // linked even if that round was overdue.
      if (before != null &&
          due.compareTo(before) > 0 &&
          before.compareTo(today) <= 0 &&
          today.compareTo(since) >= 0) {
        add(t, roundIdFor(t.id, before), today);
      }
    }
    return TaskRewardPlan(save: save, delete: delete, seen: nextSeen);
  }
}
