import 'package:flutter/material.dart';
import 'package:zero_trust_core/zero_trust_core.dart';

/// Quests in the suite. Not in the core's `ZtSuite` list yet, so the other
/// apps don't link to it before it's released.
const ZtSuiteApp questsSuiteApp = ZtSuiteApp(
  appId: 'quests',
  name: 'Quests',
  tagline: 'Daily quests for your goals, with XP and levels',
  icon: Icons.emoji_events_outlined,
  accent: Color(0xFF7C3AED), // violet
  androidPackage: 'dev.sagron.zerotrustquests',
);

const ZtAppConfig questsAppConfig = ZtAppConfig(
  appId: 'quests',
  displayName: 'Zero-Trust Quests',
  accent: Color(0xFF7C3AED),
);
