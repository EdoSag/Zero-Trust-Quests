import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zero_trust_core/zero_trust_core.dart';

import '../data/quests_store.dart';
import '../engine/engine.dart';
import '../engine/hero.dart';
import '../health/health_source.dart';
import '../health/health_sync.dart';
import '../l10n/l10n.dart';
import '../model/days.dart';
import '../model/quest.dart';
import '../notify/daily_reminder.dart';
import '../ui/home_page.dart';
import '../ui/quest_actions.dart';
import '../widgets/quests_widgets.dart';
import 'auth_providers.dart';
import 'quests_settings.dart';
import 'email_links.dart';

ReminderTexts _reminderTexts(AppL10n l) => ReminderTexts(
  channel: l.reminderChannel,
  title: l.reminderTitle,
  body: l.reminderBody,
);

/// Routes between the shared account screens and Quests.
///
/// Signed out: sign in or create an account. Signed in but locked (cold
/// start, auto-lock): unlock with the account password or biometrics. A new
/// recovery key is always shown, and confirmed, before the vault opens.
class AppGate extends ConsumerStatefulWidget {
  const AppGate({super.key});

  @override
  ConsumerState<AppGate> createState() => _AppGateState();
}

class _AppGateState extends ConsumerState<AppGate> with WidgetsBindingObserver {
  /// Stays on the sign-in screen until it hands back a result, even though
  /// Supabase reports the session a moment earlier.
  late bool _signingIn = ref.read(currentUserProvider) == null;
  UnlockResult? _awaitingRecoveryKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// A key still waiting behind the recovery-key screen is zeroed when the
  /// app leaves the foreground, so coming back asks for the password.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      final UnlockResult? pending = _awaitingRecoveryKey;
      if (pending != null) {
        pending.dek.fillRange(0, pending.dek.length, 0);
        setState(() => _awaitingRecoveryKey = null);
      }
    }
  }

  void _onUnlocked(UnlockResult result) {
    if (result.newRecoveryKey != null) {
      setState(() {
        _signingIn = false;
        _awaitingRecoveryKey = result;
      });
      return;
    }
    setState(() => _signingIn = false);
    ref
        .read(vaultControllerProvider.notifier)
        .unlock(result.dek, legacyDek: result.legacyDek);
  }

  void _forgotPassword() => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => ZtForgotPasswordScreen(redirectTo: EmailLinks.passwordReset)),
  );

  @override
  Widget build(BuildContext context) {
    ref.listen(vaultControllerProvider, (_, VaultState next) {
      // Don't leave a page open over a locked vault.
      if (next is VaultLocked) {
        Navigator.of(context).popUntil((Route<dynamic> r) => r.isFirst);
      }
    });
    ref.listen(currentUserProvider, (_, user) {
      if (user == null) {
        ref.read(vaultControllerProvider.notifier).lock();
        // The reminder belongs to this account, not the next.
        ref
            .read(dailyReminderProvider)
            .schedule(null, _reminderTexts(currentL10n))
            .ignore();
        // So do the widgets' content and the ticks queued on them.
        ref.read(questsWidgetsProvider).signedOut().ignore();
        setState(() => _signingIn = true);
      }
    });

    final UnlockResult? pending = _awaitingRecoveryKey;
    if (pending != null) {
      return ZtRecoveryKeyScreen(
        recoveryKey: pending.newRecoveryKey!,
        onDone: () {
          setState(() => _awaitingRecoveryKey = null);
          ref
              .read(vaultControllerProvider.notifier)
              .unlock(pending.dek, legacyDek: pending.legacyDek);
        },
      );
    }

    if (ref.watch(passwordRecoveryProvider)) {
      return ZtResetPasswordScreen(
        onUnlocked: (UnlockResult result) {
          ref.read(passwordRecoveryProvider.notifier).done();
          _onUnlocked(result);
        },
      );
    }

    final user = ref.watch(currentUserProvider);
    if (user == null || _signingIn) {
      return ZtSignInScreen(
        emailRedirectTo: EmailLinks.confirmed,
        onUnlocked: _onUnlocked,
        onForgotPassword: _forgotPassword,
      );
    }

    if (ref.watch(vaultControllerProvider) is VaultLocked) {
      return ZtUnlockScreen(
        email: user.email,
        onUnlocked: _onUnlocked,
        onSignOut: () => ref.read(accountServiceProvider).signOut(),
        onForgotPassword: _forgotPassword,
      );
    }

    return const QuestsHome();
  }
}

/// Quests once unlocked: runs sync, makes today's quests (again at
/// midnight), fills steps from Health Connect when that is on, keeps the
/// daily reminder set, saves steps ticked on the home screen widgets and
/// keeps the widgets up to date.
class QuestsHome extends ConsumerStatefulWidget {
  const QuestsHome({super.key});

  @override
  ConsumerState<QuestsHome> createState() => _QuestsHomeState();
}

class _QuestsHomeState extends ConsumerState<QuestsHome>
    with WidgetsBindingObserver {
  Timer? _planSoon;
  Timer? _healthTimer;
  bool _readingHealth = false;
  String? _reminderShown;
  Timer? _widgetsSoon;
  String? _widgetsShown;
  bool _applyingTicks = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _healthTimer = Timer.periodic(
      const Duration(minutes: 15),
      (_) => _fillHealth(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _plan();
      _fillHealth();
      _syncWidgets();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _planSoon?.cancel();
    _healthTimer?.cancel();
    _widgetsSoon?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(todayProvider.notifier).refresh();
      _plan();
      _fillHealth();
      _syncWidgets();
    }
  }

  /// Makes the day's missing quests once goals and quests have loaded.
  void _plan() {
    _planSoon?.cancel();
    _planSoon = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      if (ref.read(goalsProvider).value == null ||
          ref.read(questsProvider).value == null) {
        return;
      }
      try {
        await ref
            .read(questsRepositoryProvider)
            .planDay(ref.read(todayProvider));
      } on Object {
        // Tried again on the next change or resume.
      }
    });
  }

  Future<void> _fillHealth() async {
    if (_readingHealth || !mounted) return;
    if (!ref.read(questsSettingsProvider).useHealth) return;
    final quests = ref.read(questsProvider).value;
    if (quests == null) return;
    _readingHealth = true;
    try {
      final source = ref.read(healthSourceProvider);
      final repo = ref.read(questsRepositoryProvider);
      for (final day in HealthFill.daysToRead(DateTime.now())) {
        final values = await source.read(dayOf(day));
        final current = await repo.allQuests();
        for (final q in HealthFill.apply(current, day, values)) {
          await repo.saveQuest(q);
        }
      }
    } on Object {
      // Health Connect is extra; logging by hand still works.
    } finally {
      _readingHealth = false;
    }
  }

  /// Sets the next week's reminders; skips today once its quests are done.
  Future<void> _syncReminder() async {
    final minutes = ref.read(questsSettingsProvider).reminderMinutes;
    final quests = ref.read(questsProvider).value ?? const <Quest>[];
    final goals = ref.read(goalsProvider).value ?? const [];
    final day = ref.read(todayProvider);
    final todays = [
      for (final g in goals)
        if (!g.archived)
          if (QuestEngine.currentDaily(g.id, quests, day) case final q?) q,
    ];
    final allDone =
        todays.isNotEmpty &&
        todays.every(
          (q) => q.declined != null || QuestEngine.completed(q, quests),
        );
    final l = currentL10n;
    final key = '$minutes|$allDone|$day|${l.localeName}';
    if (key == _reminderShown) return;
    _reminderShown = key;
    try {
      await ref
          .read(dailyReminderProvider)
          .schedule(minutes, _reminderTexts(l), skipToday: allDone);
    } on Object {
      _reminderShown = null;
    }
  }

  /// Saves the ticks made on the widgets, then shows the widgets the
  /// current state. Debounced, so a burst of changes writes once.
  void _syncWidgets() {
    _widgetsSoon?.cancel();
    _widgetsSoon = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      try {
        await _applyWidgetTicks();
        await _publishWidgets();
      } on Object {
        // The widgets are extra; the app itself still works.
      }
    });
  }

  /// Steps ticked on the widgets, saved as if ticked here (with the
  /// celebration when one finishes a quest), also after midnight. Each is
  /// marked saved only once it is; if saving fails the rest wait for the
  /// next try.
  Future<void> _applyWidgetTicks() async {
    if (_applyingTicks) return;
    if (ref.read(questsProvider).value == null) return;
    _applyingTicks = true;
    try {
      final widgets = ref.read(questsWidgetsProvider);
      final ticks = await widgets.pending();
      if (ticks.isEmpty) return;
      final repo = ref.read(questsRepositoryProvider);
      for (final tick in ticks) {
        // The stored quest, not the screen's copy: an earlier tick in this
        // batch may already have changed it.
        final quest = (await repo.allQuests())
            .where((q) => q.id == tick.questId)
            .firstOrNull;
        final updated = quest == null ? null : tick.applyTo(quest);
        if (updated != null) {
          if (!mounted) return;
          await saveProgress(context, ref, updated);
        }
        await widgets.acknowledge(tick);
      }
    } finally {
      _applyingTicks = false;
    }
  }

  Future<void> _publishWidgets() async {
    final goals = ref.read(goalsProvider).value;
    final quests = ref.read(questsProvider).value;
    final purchases = ref.read(purchasesProvider).value;
    if (goals == null || quests == null || purchases == null) return;
    final day = ref.read(todayProvider);
    final l = currentL10n;
    final content = QuestsWidgetContent.build(
      goals: goals,
      quests: quests,
      stats: HeroStats.compute(quests, purchases, day),
      day: day,
      details: ref.read(questsSettingsProvider).widgetDetails,
      l: l,
    );
    // The widgets' texts are in the app's language: republish when it
    // changes.
    final key = '${jsonEncode(content)}|${l.localeName}';
    if (key == _widgetsShown) return;
    _widgetsShown = key;
    await ref
        .read(questsWidgetsProvider)
        .publish(content, QuestsWidgetContent.texts(l));
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(ztSyncControllerProvider);
    ref.listen(goalsProvider, (_, _) {
      _plan();
      _syncWidgets();
    });
    ref.listen(questsProvider, (_, _) {
      _plan();
      _syncReminder();
      _syncWidgets();
    });
    ref.listen(purchasesProvider, (_, _) => _syncWidgets());
    ref.listen(todayProvider, (_, _) {
      _plan();
      _syncReminder();
      _syncWidgets();
    });
    // The widget texts follow a language change; the debounce lets the new
    // language load first.
    ref.listen(ztLanguageProvider, (_, _) => _syncWidgets());
    ref.listen(questsSettingsProvider, (prev, next) {
      _syncReminder();
      _syncWidgets();
      if (next.useHealth && prev?.useHealth != true) _fillHealth();
    });
    return const HomePage();
  }
}
