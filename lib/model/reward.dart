import 'package:flutter/foundation.dart';

/// Where a [Reward] came from.
enum RewardSource {
  /// A task ticked off in ZT Tasks, in a list linked to Quests.
  task,

  /// A party's boss, beaten together.
  party;

  static RewardSource? parse(Object? v) {
    for (final s in RewardSource.values) {
      if (s.name == v) return s;
    }
    return null;
  }
}

/// XP and gold earned outside the goals' own quests. Its own item (kind
/// `reward`), with an id made from what earned it, so two phones that see
/// the same task ticked off make the same reward, never two.
///
/// - `task-<taskId>`: a one-off task, ticked off;
/// - `task-<taskId>-<dueDay>`: one round of a repeating task;
/// - `party-<spaceId>-<round>`: a party's boss, beaten.
@immutable
class Reward {
  const Reward({
    required this.id,
    required this.source,
    required this.day,
    required this.xp,
    required this.gold,
    this.title = '',
    this.ref = '',
  });

  final String id;
  final RewardSource source;

  /// The day it was earned (`yyyy-MM-dd`).
  final String day;
  final int xp;
  final int gold;

  /// What earned it: the task's title, or the boss's name.
  final String title;

  /// The task id, or the party's space id.
  final String ref;

  Map<String, Object?> toJson() => {
    'source': source.name,
    'day': day,
    'xp': xp,
    'gold': gold,
    if (title.isNotEmpty) 'title': title,
    if (ref.isNotEmpty) 'ref': ref,
  };

  /// Null for a source this version doesn't know (made by a newer one).
  static Reward? fromJson(String id, Map<String, Object?> j) {
    final source = RewardSource.parse(j['source']);
    if (source == null) return null;
    return Reward(
      id: id,
      source: source,
      day: (j['day'] as String?) ?? '2026-01-01',
      xp: (j['xp'] as num?)?.toInt() ?? 0,
      gold: (j['gold'] as num?)?.toInt() ?? 0,
      title: (j['title'] as String?) ?? '',
      ref: (j['ref'] as String?) ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Reward &&
      other.id == id &&
      other.source == source &&
      other.day == day &&
      other.xp == xp &&
      other.gold == gold &&
      other.title == title &&
      other.ref == ref;

  @override
  int get hashCode => Object.hash(id, source, day, xp, gold, title, ref);
}
