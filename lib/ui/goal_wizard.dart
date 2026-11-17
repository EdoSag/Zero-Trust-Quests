import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/quests_store.dart';
import '../engine/catalog.dart';
import '../l10n/l10n.dart';
import '../model/goal.dart';
import 'common.dart';
import 'labels.dart';

Future<void> openGoalWizard(BuildContext context, {Goal? edit}) => Navigator.of(
  context,
).push(MaterialPageRoute<void>(builder: (_) => GoalWizard(edit: edit)));

/// Sets up a goal: pick what it's about, answer a few questions (or list
/// your own habits), and the first quest is made right away.
class GoalWizard extends ConsumerStatefulWidget {
  const GoalWizard({super.key, this.edit});
  final Goal? edit;

  @override
  ConsumerState<GoalWizard> createState() => _GoalWizardState();
}

class _GoalWizardState extends ConsumerState<GoalWizard> {
  GoalCategory? _category;
  late final Map<String, String> _answers = {...?widget.edit?.answers};
  late final _name = TextEditingController(text: widget.edit?.name ?? '');
  late final List<CustomHabit> _habits = [...?widget.edit?.habits];

  /// 0: category, then one page per question, custom: habits first.
  int _page = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.edit != null) {
      _category = widget.edit!.category;
      _page = 1;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _custom => _category == GoalCategory.custom;
  List<Question> get _questions => questionsFor[_category] ?? const [];

  /// Pages after the category: custom goals get the habit list first.
  int get _pages => 1 + (_custom ? 1 : 0) + _questions.length;

  void _back() {
    if (_page == 0 || (widget.edit != null && _page == 1)) {
      Navigator.pop(context);
    } else {
      setState(() => _page--);
    }
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    final repo = ref.read(questsRepositoryProvider);
    final day = ref.read(todayProvider);
    final goal =
        widget.edit?.copyWith(
          name: _name.text.trim(),
          answers: _answers,
          habits: _habits,
        ) ??
        Goal(
          id: QuestsRepository.newId(),
          category: _category!,
          name: _name.text.trim(),
          answers: _answers,
          habits: _habits,
          createdDay: day,
        );
    await repo.saveGoal(goal);
    await repo.planDay(day);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Widget body;
    if (_page == 0) {
      body = _CategoryPage(
        onPick: (c) => setState(() {
          _category = c;
          _page = 1;
        }),
      );
    } else if (_custom && _page == 1) {
      body = _HabitsPage(
        name: _name,
        habits: _habits,
        onChanged: () => setState(() {}),
      );
    } else {
      final q = _questions[_page - 1 - (_custom ? 1 : 0)];
      body = _QuestionPage(
        question: q,
        selected: _answers[q.id] ?? q.initial,
        onPick: (o) => setState(() => _answers[q.id] = o),
      );
    }
    final last = _page == _pages - 1;
    final canGo = _page > 0 && (!_custom || _page != 1 || _habits.isNotEmpty);
    return PopScope(
      canPop: _page == 0 || (widget.edit != null && _page == 1),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.edit != null ? l.editGoal : l.newGoal),
          bottom: _page == 0
              ? null
              : PreferredSize(
                  preferredSize: const Size.fromHeight(4),
                  child: LinearProgressIndicator(
                    value: _page / (_pages - 1).clamp(1, 99),
                  ),
                ),
        ),
        body: body,
        bottomNavigationBar: _page == 0
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 52),
                    ),
                    onPressed: !canGo || _saving
                        ? null
                        : last
                        ? _finish
                        : () => setState(() => _page++),
                    child: Text(
                      last
                          ? (widget.edit != null ? l.save : l.startQuesting)
                          : l.next,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _CategoryPage extends StatelessWidget {
  const _CategoryPage({required this.onPick});
  final ValueChanged<GoalCategory> onPick;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l.whatGoal, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(l.whatGoalHint),
        const SizedBox(height: 16),
        for (final c in GoalCategory.values)
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              leading: CircleAvatar(
                backgroundColor: categoryColor(c).withValues(alpha: 0.15),
                foregroundColor: categoryColor(c),
                child: Icon(categoryIcon(c)),
              ),
              title: Text(categoryName(l, c)),
              subtitle: Text(categoryBlurb(l, c)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => onPick(c),
            ),
          ),
      ],
    );
  }
}

class _QuestionPage extends StatelessWidget {
  const _QuestionPage({
    required this.question,
    required this.selected,
    required this.onPick,
  });
  final Question question;
  final String? selected;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          questionText(l, question.id),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        for (final o in question.options)
          Card(
            color: o.id == selected ? scheme.primaryContainer : null,
            child: ListTile(
              selected: o.id == selected,
              leading: Icon(
                o.id == selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
              ),
              title: Text(optionText(l, o.id)),
              onTap: () => onPick(o.id),
            ),
          ),
      ],
    );
  }
}

class _HabitsPage extends StatefulWidget {
  const _HabitsPage({
    required this.name,
    required this.habits,
    required this.onChanged,
  });
  final TextEditingController name;
  final List<CustomHabit> habits;
  final VoidCallback onChanged;

  @override
  State<_HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends State<_HabitsPage> {
  Future<void> _edit([int? index]) async {
    final l = context.l10n;
    final old = index == null ? null : widget.habits[index];
    final label = TextEditingController(text: old?.label ?? '');
    final amount = TextEditingController(
      text: old == null || old.isCheck ? '' : fmtNum(old.amount),
    );
    final unit = TextEditingController(text: old?.unit ?? '');
    final result = await showDialog<CustomHabit>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(old == null ? l.addHabit : l.editHabit),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: label,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l.habitName,
                hintText: l.habitNameHint,
              ),
            ),
            TextField(
              controller: amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l.habitAmount,
                helperText: l.habitAmountHint,
              ),
            ),
            TextField(
              controller: unit,
              decoration: InputDecoration(
                labelText: l.habitUnit,
                hintText: l.habitUnitHint,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () {
              if (label.text.trim().isEmpty) return;
              final a =
                  double.tryParse(amount.text.trim().replaceAll(',', '.')) ?? 0;
              Navigator.pop(
                ctx,
                CustomHabit(
                  label: label.text.trim(),
                  amount: a,
                  unit: a > 0 ? unit.text.trim() : '',
                ),
              );
            },
            child: Text(l.save),
          ),
        ],
      ),
    );
    if (result == null) return;
    setState(() {
      if (index == null) {
        widget.habits.add(result);
      } else {
        widget.habits[index] = result;
      }
    });
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: widget.name,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: l.goalName,
            hintText: l.goalNameHint,
          ),
        ),
        const SizedBox(height: 24),
        Text(l.yourHabits, style: Theme.of(context).textTheme.titleMedium),
        Text(l.yourHabitsHint),
        const SizedBox(height: 8),
        for (var i = 0; i < widget.habits.length; i++)
          Card(
            child: ListTile(
              title: Text(widget.habits[i].label),
              subtitle: widget.habits[i].isCheck
                  ? Text(l.yesNoHabit)
                  : Text(
                      '${fmtNum(widget.habits[i].amount)} ${widget.habits[i].unit}'
                          .trim(),
                    ),
              onTap: () => _edit(i),
              trailing: IconButton(
                tooltip: l.delete,
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() => widget.habits.removeAt(i));
                  widget.onChanged();
                },
              ),
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
          icon: const Icon(Icons.add),
          label: Text(l.addHabit),
          onPressed: _edit,
        ),
      ],
    );
  }
}
