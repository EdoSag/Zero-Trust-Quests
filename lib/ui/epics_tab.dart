import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/quests_store.dart';
import '../engine/engine.dart';
import '../engine/events.dart';
import '../l10n/l10n.dart';
import '../model/goal.dart';
import '../model/quest.dart';
import 'common.dart';
import 'event_card.dart';
import 'labels.dart';
import 'quest_card.dart';

/// Epic quests: running ones, offers, the user's own, and finished ones.
class EpicsTab extends ConsumerWidget {
  const EpicsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final goals = ref.watch(goalsProvider).value ?? const <Goal>[];
    final quests = ref.watch(questsProvider).value ?? const <Quest>[];
    final day = ref.watch(todayProvider);
    final byId = {for (final g in goals) g.id: g};
    final epics = [
      for (final q in quests)
        if (!q.isDaily && q.declined == null) q,
    ]..sort((a, b) => b.day.compareTo(a.day));
    bool running(Quest q) =>
        (q.deadline ?? q.day).compareTo(day) >= 0 &&
        !QuestEngine.epicDone(q, quests);
    final active = [
      for (final q in epics)
        if (running(q)) q,
    ];
    final past = [
      for (final q in epics)
        if (!running(q)) q,
    ];
    final offers = [
      for (final g in goals)
        if (QuestEngine.epicOffer(g, quests, day) case final o?) (g, o),
    ];
    final events = SeasonalEvents.offers(quests, day);
    final empty =
        active.isEmpty && past.isEmpty && offers.isEmpty && events.isEmpty;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
      children: [
        if (empty)
          Padding(
            padding: const EdgeInsets.only(top: 48),
            child: EmptyState(
              icon: Icons.landscape_outlined,
              title: l.noEpicsTitle,
              body: l.noEpicsBody,
            ),
          ),
        for (final run in events)
          EventOfferCard(key: ValueKey(run.questId), run: run),
        for (final (g, o) in offers) EpicOfferCard(goal: g, offer: o),
        if (active.isNotEmpty) _Header(l.epicsRunning),
        for (final q in active)
          QuestCard(key: ValueKey(q.id), quest: q, goal: byId[q.goalId]),
        if (past.isNotEmpty) _Header(l.epicsFinished),
        for (final q in past)
          QuestCard(
            key: ValueKey(q.id),
            quest: q,
            goal: byId[q.goalId],
            readOnly: true,
          ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 16, 8, 4),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall),
  );
}

/// "A new epic quest": accept, or not now (asked again in a week).
class EpicOfferCard extends ConsumerWidget {
  const EpicOfferCard({super.key, required this.goal, required this.offer});
  final Goal goal;
  final Quest offer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final color = categoryColor(goal.category);
    return Card(
      color: color.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.landscape, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.epicOffered(goalName(l, goal)),
                    style: t.labelLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(questTitle(l, offer, goal), style: t.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                RewardChip(
                  icon: Icons.auto_awesome,
                  text: l.xpAmount(offer.xp),
                  color: xpColor,
                ),
                RewardChip(
                  icon: Icons.paid,
                  text: l.goldAmount(offer.gold),
                  color: goldColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                    ),
                    onPressed: () => ref
                        .read(questsRepositoryProvider)
                        .saveQuest(
                          offer.copyWith(declined: DeclineReason.notToday),
                        ),
                    child: Text(l.notNow),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 44),
                    ),
                    onPressed: () async {
                      await ref.read(questsRepositoryProvider).saveQuest(offer);
                      if (context.mounted) showSnack(context, l.epicAccepted);
                    },
                    child: Text(l.accept),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The user's own epic quest: a title, an amount, a unit and a deadline.
Future<void> openOwnEpic(BuildContext context, List<Goal> goals) =>
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => OwnEpicPage(goals: goals)));

class OwnEpicPage extends ConsumerStatefulWidget {
  const OwnEpicPage({super.key, required this.goals});
  final List<Goal> goals;

  @override
  ConsumerState<OwnEpicPage> createState() => _OwnEpicPageState();
}

class _OwnEpicPageState extends ConsumerState<OwnEpicPage> {
  final _title = TextEditingController();
  final _amount = TextEditingController(text: '1');
  final _unit = TextEditingController();
  late String _goalId = widget.goals.first.id;
  int _days = 14;

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _unit.dispose();
    super.dispose();
  }

  double? get _target =>
      double.tryParse(_amount.text.trim().replaceAll(',', '.'));

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ok = _title.text.trim().isNotEmpty && (_target ?? 0) > 0;
    return Scaffold(
      appBar: AppBar(title: Text(l.ownEpicTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l.ownEpicBody),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l.ownEpicName,
              hintText: l.ownEpicNameHint,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(labelText: l.ownEpicAmount),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _unit,
                  decoration: InputDecoration(
                    labelText: l.ownEpicUnit,
                    hintText: l.ownEpicUnitHint,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(l.ownEpicGoal, style: Theme.of(context).textTheme.labelLarge),
          Wrap(
            spacing: 8,
            children: [
              for (final g in widget.goals)
                ChoiceChip(
                  label: Text(goalName(l, g)),
                  selected: g.id == _goalId,
                  onSelected: (_) => setState(() => _goalId = g.id),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(l.ownEpicDays, style: Theme.of(context).textTheme.labelLarge),
          Wrap(
            spacing: 8,
            children: [
              for (final d in const [7, 14, 30, 60, 90])
                ChoiceChip(
                  label: Text(l.daysCount(d)),
                  selected: d == _days,
                  onSelected: (_) => setState(() => _days = d),
                ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            onPressed: !ok
                ? null
                : () async {
                    final goal = widget.goals.firstWhere(
                      (g) => g.id == _goalId,
                    );
                    final q = QuestEngine.ownEpic(
                      id: 'epic-own-${QuestsRepository.newId()}',
                      goal: goal,
                      title: _title.text.trim(),
                      target: _target!,
                      unit: _unit.text.trim(),
                      day: ref.read(todayProvider),
                      days: _days,
                    );
                    await ref.read(questsRepositoryProvider).saveQuest(q);
                    if (context.mounted) Navigator.pop(context);
                  },
            child: Text(l.ownEpicCreate),
          ),
        ],
      ),
    );
  }
}
