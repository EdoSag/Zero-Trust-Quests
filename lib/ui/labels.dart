import 'package:flutter/material.dart';

import '../engine/catalog.dart';
import '../engine/hero.dart';
import '../l10n/l10n.dart';
import '../model/goal.dart';
import '../model/quest.dart';
import 'common.dart';

String categoryName(AppL10n l, GoalCategory c) => switch (c) {
  GoalCategory.fitness => l.catFitness,
  GoalCategory.productivity => l.catProductivity,
  GoalCategory.nutrition => l.catNutrition,
  GoalCategory.sleep => l.catSleep,
  GoalCategory.learning => l.catLearning,
  GoalCategory.mindfulness => l.catMindfulness,
  GoalCategory.custom => l.catCustom,
};

String categoryBlurb(AppL10n l, GoalCategory c) => switch (c) {
  GoalCategory.fitness => l.catFitnessBlurb,
  GoalCategory.productivity => l.catProductivityBlurb,
  GoalCategory.nutrition => l.catNutritionBlurb,
  GoalCategory.sleep => l.catSleepBlurb,
  GoalCategory.learning => l.catLearningBlurb,
  GoalCategory.mindfulness => l.catMindfulnessBlurb,
  GoalCategory.custom => l.catCustomBlurb,
};

IconData categoryIcon(GoalCategory c) => switch (c) {
  GoalCategory.fitness => Icons.fitness_center,
  GoalCategory.productivity => Icons.bolt,
  GoalCategory.nutrition => Icons.restaurant,
  GoalCategory.sleep => Icons.bedtime_outlined,
  GoalCategory.learning => Icons.menu_book_outlined,
  GoalCategory.mindfulness => Icons.self_improvement,
  GoalCategory.custom => Icons.flag_outlined,
};

Color categoryColor(GoalCategory c) => Color(switch (c) {
  GoalCategory.fitness => 0xFFEF4444,
  GoalCategory.productivity => 0xFF3B82F6,
  GoalCategory.nutrition => 0xFF22C55E,
  GoalCategory.sleep => 0xFF6366F1,
  GoalCategory.learning => 0xFFF59E0B,
  GoalCategory.mindfulness => 0xFF14B8A6,
  GoalCategory.custom => 0xFF8B5CF6,
});

String goalName(AppL10n l, Goal g) =>
    g.name.trim().isNotEmpty ? g.name.trim() : categoryName(l, g.category);

/// "25 push-ups", "Run 2 km", "Plan tomorrow".
String activityText(AppL10n l, String id, double amount) {
  final n = fmtNum(amount);
  return switch (id) {
    'pushups' => l.actPushups(n),
    'squats' => l.actSquats(n),
    'situps' => l.actSitups(n),
    'lunges' => l.actLunges(n),
    'jumpingJacks' => l.actJumpingJacks(n),
    'burpees' => l.actBurpees(n),
    'plank' => l.actPlank(n),
    'run' => l.actRun(n),
    'walkSteps' => l.actWalkSteps(n),
    'workout' => l.actWorkout(n),
    'stretch' => l.actStretch(n),
    'deepWork' => l.actDeepWork(n),
    'pomodoros' => l.actPomodoros(n),
    'tasksDone' => l.actTasksDone(n),
    'planTomorrow' => l.actPlanTomorrow,
    'inboxZero' => l.actInboxZero,
    'noPhoneMorning' => l.actNoPhoneMorning,
    'tidyDesk' => l.actTidyDesk,
    'water' => l.actWater(n),
    'veggies' => l.actVeggies(n),
    'fruit' => l.actFruit(n),
    'homeMeal' => l.actHomeMeal,
    'noSugaryDrinks' => l.actNoSugaryDrinks,
    'noLateSnack' => l.actNoLateSnack,
    'protein' => l.actProtein,
    'sleepHours' => l.actSleepHours(n),
    'bedOnTime' => l.actBedOnTime,
    'noScreensBed' => l.actNoScreensBed(n),
    'morningLight' => l.actMorningLight(n),
    'noCaffeineLate' => l.actNoCaffeineLate,
    'readPages' => l.actReadPages(n),
    'study' => l.actStudy(n),
    'newWords' => l.actNewWords(n),
    'lesson' => l.actLesson,
    'teachBack' => l.actTeachBack,
    'meditate' => l.actMeditate(n),
    'gratitude' => l.actGratitude(n),
    'walkOutside' => l.actWalkOutside(n),
    'journal' => l.actJournal,
    'breathing' => l.actBreathing(n),
    'streak' => l.actStreak(n),
    _ => n,
  };
}

String stepText(AppL10n l, QuestStep s) {
  if (s.activity == 'custom') {
    if (s.target <= 1 && s.unit.isEmpty) return s.label;
    return l.customStep(s.label, fmtNum(s.target), s.unit);
  }
  return activityText(l, s.activity, s.target);
}

bool isCheckStep(QuestStep s) => s.activity == 'custom'
    ? s.target <= 1 && s.unit.isEmpty
    : activityById[s.activity]?.isCheck ?? false;

/// "12 of 25 km" style progress, short.
String progressText(AppL10n l, QuestStep s) =>
    l.progressOf(fmtNum(s.progress), fmtNum(s.target));

String questTitle(AppL10n l, Quest q, Goal? g) {
  if (q.title.isNotEmpty) return q.title;
  if (q.isDaily) return g == null ? l.dailyQuest : goalName(l, g);
  final s = q.steps.isEmpty ? null : q.steps.first;
  final days = q.deadline == null ? 0 : _span(q.day, q.deadline!);
  return switch (q.mode) {
    EpicMode.streak => l.epicStreakTitle(fmtNum(s?.target ?? 0), days),
    EpicMode.best => l.epicBestTitle(s == null ? '' : stepText(l, s)),
    EpicMode.total => l.epicTotalTitle(s == null ? '' : stepText(l, s), days),
  };
}

int _span(String from, String to) =>
    DateTime.parse(to).difference(DateTime.parse(from)).inDays + 1;

String declineReasonText(AppL10n l, DeclineReason r) => switch (r) {
  DeclineReason.tooHard => l.declineTooHard,
  DeclineReason.tooEasy => l.declineTooEasy,
  DeclineReason.different => l.declineDifferent,
  DeclineReason.notToday => l.declineNotToday,
};

String questionText(AppL10n l, String id) => switch (id) {
  'level' => l.qLevel,
  'time' => l.qTime,
  'pushups' => l.qPushups,
  'running' => l.qRunning,
  'focus' => l.qFocus,
  'focusNow' => l.qFocusNow,
  'struggle' => l.qStruggle,
  'waterNow' => l.qWaterNow,
  'veggiesNow' => l.qVeggiesNow,
  'sleepNow' => l.qSleepNow,
  'readNow' => l.qReadNow,
  'kind' => l.qKind,
  'meditateNow' => l.qMeditateNow,
  _ => id,
};

String optionText(AppL10n l, String id) => switch (id) {
  'beginner' => l.optBeginner,
  'some' => l.optSome,
  'experienced' => l.optExperienced,
  'min10' => l.optMin10,
  'min20' => l.optMin20,
  'min40' => l.optMin40,
  'min60' => l.optMin60,
  'p0' => l.optP0,
  'p10' => l.optP10,
  'p25' => l.optP25,
  'p40' => l.optP40,
  'r0' => l.optR0,
  'r2' => l.optR2,
  'r5' => l.optR5,
  'r10' => l.optR10,
  'strength' => l.optStrength,
  'cardio' => l.optCardio,
  'mix' => l.optMix,
  'f15' => l.optF15,
  'f30' => l.optF30,
  'f60' => l.optF60,
  'procrastination' => l.optProcrastination,
  'distraction' => l.optDistraction,
  'planning' => l.optPlanning,
  'w2' => l.optW2,
  'w5' => l.optW5,
  'w8' => l.optW8,
  'v0' => l.optV0,
  'v2' => l.optV2,
  'v4' => l.optV4,
  'sugar' => l.optSugar,
  'snacking' => l.optSnacking,
  'cooking' => l.optCooking,
  's5' => l.optS5,
  's6' => l.optS6,
  's7' => l.optS7,
  's8' => l.optS8,
  'lateBed' => l.optLateBed,
  'screens' => l.optScreens,
  'mornings' => l.optMornings,
  'read0' => l.optRead0,
  'read10' => l.optRead10,
  'read30' => l.optRead30,
  'language' => l.optLanguage,
  'skill' => l.optSkill,
  'books' => l.optBooks,
  'never' => l.optNever,
  'sometimes' => l.optSometimes,
  'daily' => l.optDaily,
  'stress' => l.optStress,
  'mood' => l.optMood,
  'outdoors' => l.optOutdoors,
  _ => id,
};

String heroTitle(AppL10n l, int level) => switch (Levels.titleFor(level)) {
  'apprentice' => l.titleApprentice,
  'adventurer' => l.titleAdventurer,
  'pathfinder' => l.titlePathfinder,
  'veteran' => l.titleVeteran,
  'hero' => l.titleHero,
  'champion' => l.titleChampion,
  'master' => l.titleMaster,
  'legend' => l.titleLegend,
  _ => l.titleNovice,
};

IconData emblemIcon(String id) => switch (id) {
  'sword' => Icons.colorize,
  'flame' => Icons.local_fire_department,
  'compass' => Icons.explore,
  'star' => Icons.star,
  'leaf' => Icons.eco,
  'bolt' => Icons.bolt,
  'rocket' => Icons.rocket_launch,
  'crown' => Icons.workspace_premium,
  'diamond' => Icons.diamond,
  'dragon' => Icons.whatshot,
  'trophy' => Icons.emoji_events,
  _ => Icons.shield,
};

Color heroColor(String id) =>
    Color(Shop.colorValues[id] ?? Shop.colorValues['teal']!);
