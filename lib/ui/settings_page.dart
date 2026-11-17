import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zero_trust_core/zero_trust_core.dart';

import '../app/quests_settings.dart';
import '../health/health_source.dart';
import '../l10n/l10n.dart';
import '../notify/daily_reminder.dart';
import 'common.dart';

/// The shared Zero-Trust settings screen, with Quests' own rows.
class QuestsSettingsPage extends ConsumerWidget {
  const QuestsSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final settings = ref.watch(questsSettingsProvider);
    final reminder = settings.reminderMinutes;
    return ZtSettingsPage(
      showSyncStatus: true,
      onSignedOut: () => Navigator.of(context).popUntil((r) => r.isFirst),
      onOpenUrl: (url) => launchUrl(url, mode: LaunchMode.externalApplication),
      privacyPolicyUrl: Uri.parse('https://zerotrust.bz/privacy'),
      termsUrl: Uri.parse('https://zerotrust.bz/terms'),
      supportUrl: Uri.parse('https://zerotrust.bz/support'),
      appSection: [
        SwitchListTile(
          secondary: const Icon(Icons.favorite_border),
          title: Text(l.useHealth),
          subtitle: Text(l.useHealthHint),
          value: settings.useHealth,
          onChanged: (on) async {
            if (on) {
              final source = ref.read(healthSourceProvider);
              if (!await source.available()) {
                if (context.mounted) showSnack(context, l.healthUnavailable);
                return;
              }
              if (!await source.requestAccess()) {
                if (context.mounted) showSnack(context, l.healthRefused);
                return;
              }
            }
            await ref.read(questsSettingsProvider.notifier).setUseHealth(on);
          },
        ),
        ListTile(
          leading: const Icon(Icons.notifications_outlined),
          title: Text(l.dailyReminder),
          subtitle: Text(
            reminder == null
                ? l.off
                : MaterialLocalizations.of(context).formatTimeOfDay(
                    TimeOfDay(hour: reminder ~/ 60, minute: reminder % 60),
                    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(
                      context,
                    ),
                  ),
          ),
          trailing: reminder == null
              ? null
              : IconButton(
                  tooltip: l.turnOff,
                  icon: const Icon(Icons.notifications_off_outlined),
                  onPressed: () => ref
                      .read(questsSettingsProvider.notifier)
                      .setReminder(null),
                ),
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay(
                hour: (reminder ?? 480) ~/ 60,
                minute: (reminder ?? 480) % 60,
              ),
            );
            if (picked == null) return;
            if (!await ref.read(dailyReminderProvider).requestPermission()) {
              if (context.mounted) showSnack(context, l.notificationsRefused);
              return;
            }
            await ref
                .read(questsSettingsProvider.notifier)
                .setReminder(picked.hour * 60 + picked.minute);
          },
        ),
      ],
    );
  }
}
