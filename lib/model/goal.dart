import 'package:flutter/foundation.dart';

/// What a goal is about. Picks the activities quests are made from and the
/// questions asked when the goal is set up.
enum GoalCategory {
  fitness,
  productivity,
  nutrition,
  sleep,
  learning,
  mindfulness,
  custom;

  static GoalCategory parse(Object? v) => GoalCategory.values.firstWhere(
    (c) => c.name == v,
    orElse: () => GoalCategory.custom,
  );
}

/// One habit of a custom goal: "Practise guitar, 20 minutes". An [amount]
/// of 0 is a yes/no habit ("Call mum").
@immutable
class CustomHabit {
  const CustomHabit({required this.label, this.amount = 0, this.unit = ''});

  final String label;
  final double amount;
  final String unit;

  bool get isCheck => amount <= 0;

  Map<String, Object?> toJson() => {
    'label': label,
    'amount': amount,
    'unit': unit,
  };

  static CustomHabit fromJson(Map<String, Object?> j) => CustomHabit(
    label: (j['label'] as String?) ?? '',
    amount: (j['amount'] as num?)?.toDouble() ?? 0,
    unit: (j['unit'] as String?) ?? '',
  );

  @override
  bool operator ==(Object other) =>
      other is CustomHabit &&
      other.label == label &&
      other.amount == amount &&
      other.unit == unit;

  @override
  int get hashCode => Object.hash(label, amount, unit);
}

/// A goal the user is working towards. Its answers to the set-up questions
/// size the quests; how the user does on them moves the difficulty.
@immutable
class Goal {
  const Goal({
    required this.id,
    required this.category,
    this.name = '',
    this.answers = const {},
    this.habits = const [],
    required this.createdDay,
    this.archived = false,
  });

  final String id;
  final GoalCategory category;

  /// The user's own name for it. Empty: the category's name is shown.
  final String name;

  /// Question id -> option id, from the set-up questions.
  final Map<String, String> answers;

  /// Custom goals only.
  final List<CustomHabit> habits;

  /// The day the goal was set (`yyyy-MM-dd`).
  final String createdDay;

  /// No new quests; history and XP stay.
  final bool archived;

  Goal copyWith({
    String? name,
    Map<String, String>? answers,
    List<CustomHabit>? habits,
    bool? archived,
  }) => Goal(
    id: id,
    category: category,
    name: name ?? this.name,
    answers: answers ?? this.answers,
    habits: habits ?? this.habits,
    createdDay: createdDay,
    archived: archived ?? this.archived,
  );

  Map<String, Object?> toJson() => {
    'category': category.name,
    'name': name,
    'answers': answers,
    'habits': [for (final h in habits) h.toJson()],
    'createdDay': createdDay,
    'archived': archived,
  };

  static Goal fromJson(String id, Map<String, Object?> j) => Goal(
    id: id,
    category: GoalCategory.parse(j['category']),
    name: (j['name'] as String?) ?? '',
    answers: {
      for (final e in ((j['answers'] as Map?) ?? const {}).entries)
        '${e.key}': '${e.value}',
    },
    habits: [
      for (final h in (j['habits'] as List?) ?? const [])
        if (h is Map) CustomHabit.fromJson(h.cast<String, Object?>()),
    ],
    createdDay: (j['createdDay'] as String?) ?? '2026-01-01',
    archived: j['archived'] == true,
  );
}
