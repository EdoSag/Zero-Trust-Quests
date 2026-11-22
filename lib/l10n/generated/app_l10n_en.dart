// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_l10n.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ZT Quests';

  @override
  String actPushups(String n) {
    return '$n push-ups';
  }

  @override
  String actSquats(String n) {
    return '$n squats';
  }

  @override
  String actSitups(String n) {
    return '$n sit-ups';
  }

  @override
  String actLunges(String n) {
    return '$n lunges';
  }

  @override
  String actJumpingJacks(String n) {
    return '$n jumping jacks';
  }

  @override
  String actBurpees(String n) {
    return '$n burpees';
  }

  @override
  String actPlank(String n) {
    return 'Plank for $n seconds';
  }

  @override
  String actRun(String n) {
    return 'Run $n km';
  }

  @override
  String actWalkSteps(String n) {
    return 'Walk $n steps';
  }

  @override
  String actWorkout(String n) {
    return 'Work out for $n minutes';
  }

  @override
  String actStretch(String n) {
    return 'Stretch for $n minutes';
  }

  @override
  String actDeepWork(String n) {
    return '$n minutes of focused work';
  }

  @override
  String actPomodoros(String n) {
    return '$n pomodoros (25-minute focus blocks)';
  }

  @override
  String actTasksDone(String n) {
    return 'Finish $n tasks';
  }

  @override
  String get actPlanTomorrow => 'Plan tomorrow before bed';

  @override
  String get actInboxZero => 'Clear your inbox';

  @override
  String get actNoPhoneMorning => 'No phone for the first hour of the day';

  @override
  String get actTidyDesk => 'Tidy your desk';

  @override
  String actWater(String n) {
    return 'Drink $n glasses of water';
  }

  @override
  String actVeggies(String n) {
    return 'Eat $n servings of vegetables';
  }

  @override
  String actFruit(String n) {
    return 'Eat $n pieces of fruit';
  }

  @override
  String get actHomeMeal => 'Cook a meal at home';

  @override
  String get actNoSugaryDrinks => 'No sugary drinks today';

  @override
  String get actNoLateSnack => 'No snacks after dinner';

  @override
  String get actProtein => 'Protein in every meal';

  @override
  String actSleepHours(String n) {
    return 'Sleep $n hours';
  }

  @override
  String get actBedOnTime => 'In bed by your bedtime';

  @override
  String actNoScreensBed(String n) {
    return 'No screens $n minutes before bed';
  }

  @override
  String actMorningLight(String n) {
    return '$n minutes of daylight in the morning';
  }

  @override
  String get actNoCaffeineLate => 'No caffeine after 2 pm';

  @override
  String actReadPages(String n) {
    return 'Read $n pages';
  }

  @override
  String actStudy(String n) {
    return 'Study for $n minutes';
  }

  @override
  String actNewWords(String n) {
    return 'Learn $n new words';
  }

  @override
  String get actLesson => 'Take one lesson or watch one lecture';

  @override
  String get actTeachBack => 'Explain what you learned to someone';

  @override
  String actMeditate(String n) {
    return 'Meditate for $n minutes';
  }

  @override
  String actGratitude(String n) {
    return 'Write down $n things you are grateful for';
  }

  @override
  String actWalkOutside(String n) {
    return 'Walk outside for $n minutes';
  }

  @override
  String get actJournal => 'Write in your journal';

  @override
  String actBreathing(String n) {
    return '$n minutes of slow breathing';
  }

  @override
  String actStreak(String n) {
    return 'Complete your daily quest on $n days';
  }

  @override
  String customStep(String label, String amount, String unit) {
    return '$label: $amount $unit';
  }

  @override
  String progressOf(String done, String target) {
    return '$done of $target';
  }

  @override
  String get catFitness => 'Get fitter';

  @override
  String get catFitnessBlurb => 'Strength, running, steps and workouts';

  @override
  String get catProductivity => 'Be more productive';

  @override
  String get catProductivityBlurb => 'Focus, getting things done, planning';

  @override
  String get catNutrition => 'Eat healthier';

  @override
  String get catNutritionBlurb => 'Water, vegetables, fewer sweets';

  @override
  String get catSleep => 'Sleep better';

  @override
  String get catSleepBlurb => 'Enough sleep, a steady bedtime, calmer evenings';

  @override
  String get catLearning => 'Learn something';

  @override
  String get catLearningBlurb => 'Reading, a language, a new skill';

  @override
  String get catMindfulness => 'Feel calmer';

  @override
  String get catMindfulnessBlurb => 'Meditation, gratitude, time outside';

  @override
  String get catCustom => 'My own goal';

  @override
  String get catCustomBlurb => 'Anything else: you choose the habits';

  @override
  String get qLevel => 'Where are you starting from?';

  @override
  String get qTime => 'How much time can you give it each day?';

  @override
  String get qPushups => 'How many push-ups can you do in a row?';

  @override
  String get qRunning => 'What is the longest you have run lately?';

  @override
  String get qFocus => 'What do you want more of?';

  @override
  String get qFocusNow => 'How long can you focus without a break?';

  @override
  String get qStruggle => 'What gets in the way most?';

  @override
  String get qWaterNow => 'How much water do you drink a day?';

  @override
  String get qVeggiesNow => 'How many servings of vegetables a day?';

  @override
  String get qSleepNow => 'How long do you usually sleep?';

  @override
  String get qReadNow => 'How much do you read on a normal day?';

  @override
  String get qKind => 'What are you learning?';

  @override
  String get qMeditateNow => 'Do you meditate?';

  @override
  String get optBeginner => 'Just starting';

  @override
  String get optSome => 'Some experience';

  @override
  String get optExperienced => 'Experienced';

  @override
  String get optMin10 => 'About 10 minutes';

  @override
  String get optMin20 => 'About 20 minutes';

  @override
  String get optMin40 => 'About 40 minutes';

  @override
  String get optMin60 => 'An hour or more';

  @override
  String get optP0 => 'Fewer than 5';

  @override
  String get optP10 => '5 to 15';

  @override
  String get optP25 => '15 to 30';

  @override
  String get optP40 => 'More than 30';

  @override
  String get optR0 => 'I don\'t run';

  @override
  String get optR2 => 'Up to 2 km';

  @override
  String get optR5 => '2 to 5 km';

  @override
  String get optR10 => 'More than 5 km';

  @override
  String get optStrength => 'Strength';

  @override
  String get optCardio => 'Cardio and endurance';

  @override
  String get optMix => 'A mix';

  @override
  String get optF15 => 'About 15 minutes';

  @override
  String get optF30 => 'About 30 minutes';

  @override
  String get optF60 => 'An hour or more';

  @override
  String get optProcrastination => 'Putting things off';

  @override
  String get optDistraction => 'Distractions and my phone';

  @override
  String get optPlanning => 'No plan for the day';

  @override
  String get optW2 => '1 to 3 glasses';

  @override
  String get optW5 => '4 to 6 glasses';

  @override
  String get optW8 => '7 or more';

  @override
  String get optV0 => 'Hardly any';

  @override
  String get optV2 => '1 to 3';

  @override
  String get optV4 => '4 or more';

  @override
  String get optSugar => 'Sweets and sugary drinks';

  @override
  String get optSnacking => 'Snacking';

  @override
  String get optCooking => 'Not cooking at home';

  @override
  String get optS5 => 'Under 6 hours';

  @override
  String get optS6 => '6 to 7 hours';

  @override
  String get optS7 => '7 to 8 hours';

  @override
  String get optS8 => '8 hours or more';

  @override
  String get optLateBed => 'Going to bed late';

  @override
  String get optScreens => 'Screens before bed';

  @override
  String get optMornings => 'Hard mornings';

  @override
  String get optRead0 => 'Hardly at all';

  @override
  String get optRead10 => 'A few pages';

  @override
  String get optRead30 => 'A chapter or more';

  @override
  String get optLanguage => 'A language';

  @override
  String get optSkill => 'A skill or a course';

  @override
  String get optBooks => 'Reading more books';

  @override
  String get optNever => 'Never tried';

  @override
  String get optSometimes => 'Sometimes';

  @override
  String get optDaily => 'Most days';

  @override
  String get optStress => 'Stress';

  @override
  String get optMood => 'Low mood';

  @override
  String get optOutdoors => 'Too much time indoors';

  @override
  String get titleNovice => 'Novice';

  @override
  String get titleApprentice => 'Apprentice';

  @override
  String get titleAdventurer => 'Adventurer';

  @override
  String get titlePathfinder => 'Pathfinder';

  @override
  String get titleVeteran => 'Veteran';

  @override
  String get titleHero => 'Hero';

  @override
  String get titleChampion => 'Champion';

  @override
  String get titleMaster => 'Master';

  @override
  String get titleLegend => 'Legend';

  @override
  String get accept => 'Accept';

  @override
  String get add => 'Add';

  @override
  String addRest(String n) {
    return '+$n (the rest)';
  }

  @override
  String get amountDone => 'How much did you do?';

  @override
  String get bestSoFar => 'Your best so far';

  @override
  String get setTotal => 'Set as total';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get more => 'More';

  @override
  String get next => 'Next';

  @override
  String get settings => 'Settings';

  @override
  String get notSet => 'Not set';

  @override
  String get off => 'Off';

  @override
  String get turnOff => 'Turn off';

  @override
  String get onward => 'Onward!';

  @override
  String get couldNotLoad => 'Could not load your quests';

  @override
  String get tabToday => 'Today';

  @override
  String get tabEpics => 'Epics';

  @override
  String get tabGoals => 'Goals';

  @override
  String get tabHero => 'Hero';

  @override
  String get dailyQuest => 'Daily quest';

  @override
  String get completed => 'Completed';

  @override
  String get missed => 'Missed';

  @override
  String get skippedToday => 'Skipped today';

  @override
  String difficultyValue(String d) {
    return 'difficulty $d×';
  }

  @override
  String daysLeft(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days left',
      one: 'Last day',
    );
    return '$_temp0';
  }

  @override
  String endedOn(String day) {
    return 'Ended $day';
  }

  @override
  String xpAmount(int n) {
    return '+$n XP';
  }

  @override
  String goldAmount(int n) {
    return '$n gold';
  }

  @override
  String get logProgress => 'Log progress';

  @override
  String get fromHealthConnect => 'Filled from Health Connect when it is on';

  @override
  String get questComplete => 'Quest complete!';

  @override
  String get epicComplete => 'Epic quest complete!';

  @override
  String levelUp(int n) {
    return 'Level up! You reached level $n';
  }

  @override
  String levelTitle(int n, String title) {
    return 'Level $n · $title';
  }

  @override
  String levelShort(int n) {
    return 'Lvl $n';
  }

  @override
  String xpToNext(int have, int need, int next) {
    return '$have / $need XP to level $next';
  }

  @override
  String streakDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n-day streak',
      one: '1-day streak',
    );
    return '$_temp0';
  }

  @override
  String freezesHeld(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'freezes',
      one: 'freeze',
    );
    return '$n streak $_temp0';
  }

  @override
  String get declineAction => 'Decline quest';

  @override
  String get declineTitle => 'Why decline it?';

  @override
  String get declineFree => 'Your first decline today is free.';

  @override
  String declineCosts(int n) {
    return 'You already declined one today: this one costs $n gold.';
  }

  @override
  String get declineTooHard => 'Too hard';

  @override
  String get declineTooHardHint =>
      'Get an easier quest. Future quests get easier too.';

  @override
  String get declineTooEasy => 'Too easy';

  @override
  String get declineTooEasyHint =>
      'Get a harder quest. Future quests get harder too.';

  @override
  String get declineDifferent => 'Something else';

  @override
  String get declineDifferentHint => 'Same difficulty, different activities.';

  @override
  String get declineNotToday => 'Not today';

  @override
  String get declineNotTodayHint => 'Skip this goal today. Back tomorrow.';

  @override
  String get notEnoughGold =>
      'Not enough gold yet. Complete quests to earn more.';

  @override
  String get noMoreSwaps => 'No more swaps for this goal today.';

  @override
  String epicStreakTitle(String n, int days) {
    return 'Complete $n daily quests within $days days';
  }

  @override
  String epicBestTitle(String what) {
    return 'In one day: $what';
  }

  @override
  String epicTotalTitle(String what, int days) {
    return '$what in total, within $days days';
  }

  @override
  String epicOffered(String goal) {
    return 'New epic quest · $goal';
  }

  @override
  String get epicAccepted =>
      'Epic quest accepted. Your daily quests count towards it.';

  @override
  String get notNow => 'Not now';

  @override
  String get epicsRunning => 'In progress';

  @override
  String get epicsFinished => 'Finished';

  @override
  String get noEpicsTitle => 'No epic quests yet';

  @override
  String get noEpicsBody =>
      'Complete a few daily quests and your goals will offer bigger challenges. You can also set your own.';

  @override
  String get ownEpicTitle => 'Own epic quest';

  @override
  String get ownEpicBody =>
      'A big goal with a deadline, like \"Run a half marathon\" or \"Read 3 books\". Log progress whenever you make some.';

  @override
  String get ownEpicName => 'What is the quest?';

  @override
  String get ownEpicNameHint => 'Read 3 books';

  @override
  String get ownEpicAmount => 'Target';

  @override
  String get ownEpicUnit => 'Unit';

  @override
  String get ownEpicUnitHint => 'books';

  @override
  String get ownEpicGoal => 'Goal it belongs to';

  @override
  String get ownEpicDays => 'Time to finish';

  @override
  String get ownEpicCreate => 'Start the quest';

  @override
  String daysCount(int n) {
    return '$n days';
  }

  @override
  String get firstGoalTitle => 'What do you want to get better at?';

  @override
  String get firstGoalBody =>
      'Pick a goal and answer a few questions. You get a daily quest sized for you, and it adapts as you go.';

  @override
  String get chooseGoal => 'Choose a goal';

  @override
  String get newGoal => 'New goal';

  @override
  String get editGoal => 'Edit goal';

  @override
  String get whatGoal => 'What is your goal?';

  @override
  String get whatGoalHint => 'You can add more goals later.';

  @override
  String get startQuesting => 'Start questing';

  @override
  String get goalName => 'Name of the goal';

  @override
  String get goalNameHint => 'Play the guitar';

  @override
  String get yourHabits => 'Your habits';

  @override
  String get yourHabitsHint => 'Quests are made from these. Add at least one.';

  @override
  String get addHabit => 'Add a habit';

  @override
  String get editHabit => 'Edit habit';

  @override
  String get habitName => 'Habit';

  @override
  String get habitNameHint => 'Practise guitar';

  @override
  String get habitAmount => 'Amount (optional)';

  @override
  String get habitAmountHint => 'Leave empty for a yes/no habit';

  @override
  String get habitUnit => 'Unit';

  @override
  String get habitUnitHint => 'minutes';

  @override
  String get yesNoHabit => 'Yes / no';

  @override
  String get archivedGoals => 'Archived';

  @override
  String weekDone(int done, int made) {
    return '$done/$made this week';
  }

  @override
  String get editAnswers => 'Change answers';

  @override
  String get archiveGoal => 'Archive';

  @override
  String get unarchiveGoal => 'Bring back';

  @override
  String get deleteGoalTitle => 'Delete this goal?';

  @override
  String get deleteGoalBody =>
      'Its quests are deleted too, with the XP and gold they earned. To keep them, archive the goal instead.';

  @override
  String get statQuestsDone => 'Quests done';

  @override
  String get statDifficulty => 'Difficulty now';

  @override
  String get statSince => 'Since';

  @override
  String get difficultyExplained =>
      'Difficulty starts from your answers. Each completed quest raises it a little, quests left under half done lower it, and declining as too hard or too easy changes it right away.';

  @override
  String get statDailies => 'Daily quests';

  @override
  String get statEpics => 'Epic quests';

  @override
  String get statBestStreak => 'Best streak';

  @override
  String get statTotalXp => 'Total XP';

  @override
  String get heroName => 'Hero name';

  @override
  String get shop => 'Shop';

  @override
  String get shopHint =>
      'Spend gold here. Some items unlock for free as you level up.';

  @override
  String get streakFreeze => 'Streak freeze';

  @override
  String streakFreezeHint(int n) {
    return 'Keeps your streak through one missed day. Hold up to $n.';
  }

  @override
  String get emblems => 'Emblems';

  @override
  String get colors => 'Colours';

  @override
  String get wear => 'Use';

  @override
  String get wearing => 'In use';

  @override
  String get buy => 'Buy';

  @override
  String get buyTitle => 'Buy this?';

  @override
  String buyBody(int n) {
    return 'It costs $n gold.';
  }

  @override
  String get useHealth => 'Use Health Connect';

  @override
  String get useHealthHint =>
      'Fill steps, distance, workouts, sleep and water on their own, from ZT Fitness (turn on \"Save workouts and water to Health Connect\" in its settings), your watch or other apps. Read on this phone only.';

  @override
  String get healthUnavailable =>
      'Health Connect is not available on this phone.';

  @override
  String get healthRefused => 'Health Connect access was not allowed.';

  @override
  String get dailyReminder => 'Daily reminder';

  @override
  String get notificationsRefused =>
      'Notifications are off for ZT Quests in the phone settings.';

  @override
  String get reminderChannel => 'Daily quests';

  @override
  String get reminderTitle => 'Your quests are waiting';

  @override
  String get reminderBody =>
      'Today\'s quests are ready. Keep your streak going!';

  @override
  String get widgetDetails => 'Show details on the home screen';

  @override
  String get widgetDetailsBody =>
      'Off: the widgets show your level, gold, streak and how many steps are left. On: the steps of today\'s quests and your goal names are stored unencrypted on this phone for the home screen.';

  @override
  String get widgetTodayTitle => 'Today\'s quest';

  @override
  String widgetStepsDone(String done, String total) {
    return '$done of $total steps done';
  }

  @override
  String get widgetAllDone => 'All done for today!';

  @override
  String get widgetSignedOut => 'Signed out';

  @override
  String get widgetOpenToSee => 'Open ZT Quests to see your quests';

  @override
  String get widgetNewDay => 'New quests are ready. Open ZT Quests.';

  @override
  String get widgetNoQuests => 'No quests today. Add a goal in ZT Quests.';

  @override
  String get widgetCompleteStep => 'Complete this step';

  @override
  String widgetLevel(String level) {
    return 'Level $level';
  }

  @override
  String widgetXp(String xp, String need) {
    return '$xp / $need XP';
  }

  @override
  String widgetGold(String gold) {
    return '$gold gold';
  }

  @override
  String get widgetStreak => 'Streak';

  @override
  String get widgetStreakWarn => 'Do a quest today';

  @override
  String get widgetStreakDone => 'Done today';

  @override
  String get widgetNextStep => 'Next step';

  @override
  String widgetStepsLeft(String count) {
    return 'Steps left: $count';
  }

  @override
  String get widgetOpenApp => 'Open ZT Quests';

  @override
  String get workoutAccessTitle => 'Count your workouts';

  @override
  String get workoutAccessBody =>
      'Workouts from ZT Fitness or your watch can fill workout, run, stretching and walking quests. Health Connect shares them only when ZT Quests may also read calories burned. Read on this phone only.';

  @override
  String get workoutAccessAllow => 'Allow';
}
