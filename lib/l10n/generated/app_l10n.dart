import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_l10n_en.dart';
import 'app_l10n_he.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppL10n
/// returned by `AppL10n.of(context)`.
///
/// Applications need to include `AppL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_l10n.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppL10n.localizationsDelegates,
///   supportedLocales: AppL10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppL10n.supportedLocales
/// property.
abstract class AppL10n {
  AppL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n)!;
  }

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('he'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'ZT Quests'**
  String get appTitle;

  /// No description provided for @actPushups.
  ///
  /// In en, this message translates to:
  /// **'{n} push-ups'**
  String actPushups(String n);

  /// No description provided for @actSquats.
  ///
  /// In en, this message translates to:
  /// **'{n} squats'**
  String actSquats(String n);

  /// No description provided for @actSitups.
  ///
  /// In en, this message translates to:
  /// **'{n} sit-ups'**
  String actSitups(String n);

  /// No description provided for @actLunges.
  ///
  /// In en, this message translates to:
  /// **'{n} lunges'**
  String actLunges(String n);

  /// No description provided for @actJumpingJacks.
  ///
  /// In en, this message translates to:
  /// **'{n} jumping jacks'**
  String actJumpingJacks(String n);

  /// No description provided for @actBurpees.
  ///
  /// In en, this message translates to:
  /// **'{n} burpees'**
  String actBurpees(String n);

  /// No description provided for @actPlank.
  ///
  /// In en, this message translates to:
  /// **'Plank for {n} seconds'**
  String actPlank(String n);

  /// No description provided for @actRun.
  ///
  /// In en, this message translates to:
  /// **'Run {n} km'**
  String actRun(String n);

  /// No description provided for @actWalkSteps.
  ///
  /// In en, this message translates to:
  /// **'Walk {n} steps'**
  String actWalkSteps(String n);

  /// No description provided for @actWorkout.
  ///
  /// In en, this message translates to:
  /// **'Work out for {n} minutes'**
  String actWorkout(String n);

  /// No description provided for @actStretch.
  ///
  /// In en, this message translates to:
  /// **'Stretch for {n} minutes'**
  String actStretch(String n);

  /// No description provided for @actDeepWork.
  ///
  /// In en, this message translates to:
  /// **'{n} minutes of focused work'**
  String actDeepWork(String n);

  /// No description provided for @actPomodoros.
  ///
  /// In en, this message translates to:
  /// **'{n} pomodoros (25-minute focus blocks)'**
  String actPomodoros(String n);

  /// No description provided for @actTasksDone.
  ///
  /// In en, this message translates to:
  /// **'Finish {n} tasks'**
  String actTasksDone(String n);

  /// No description provided for @actPlanTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Plan tomorrow before bed'**
  String get actPlanTomorrow;

  /// No description provided for @actInboxZero.
  ///
  /// In en, this message translates to:
  /// **'Clear your inbox'**
  String get actInboxZero;

  /// No description provided for @actNoPhoneMorning.
  ///
  /// In en, this message translates to:
  /// **'No phone for the first hour of the day'**
  String get actNoPhoneMorning;

  /// No description provided for @actTidyDesk.
  ///
  /// In en, this message translates to:
  /// **'Tidy your desk'**
  String get actTidyDesk;

  /// No description provided for @actWater.
  ///
  /// In en, this message translates to:
  /// **'Drink {n} glasses of water'**
  String actWater(String n);

  /// No description provided for @actVeggies.
  ///
  /// In en, this message translates to:
  /// **'Eat {n} servings of vegetables'**
  String actVeggies(String n);

  /// No description provided for @actFruit.
  ///
  /// In en, this message translates to:
  /// **'Eat {n} pieces of fruit'**
  String actFruit(String n);

  /// No description provided for @actHomeMeal.
  ///
  /// In en, this message translates to:
  /// **'Cook a meal at home'**
  String get actHomeMeal;

  /// No description provided for @actNoSugaryDrinks.
  ///
  /// In en, this message translates to:
  /// **'No sugary drinks today'**
  String get actNoSugaryDrinks;

  /// No description provided for @actNoLateSnack.
  ///
  /// In en, this message translates to:
  /// **'No snacks after dinner'**
  String get actNoLateSnack;

  /// No description provided for @actProtein.
  ///
  /// In en, this message translates to:
  /// **'Protein in every meal'**
  String get actProtein;

  /// No description provided for @actSleepHours.
  ///
  /// In en, this message translates to:
  /// **'Sleep {n} hours'**
  String actSleepHours(String n);

  /// No description provided for @actBedOnTime.
  ///
  /// In en, this message translates to:
  /// **'In bed by your bedtime'**
  String get actBedOnTime;

  /// No description provided for @actNoScreensBed.
  ///
  /// In en, this message translates to:
  /// **'No screens {n} minutes before bed'**
  String actNoScreensBed(String n);

  /// No description provided for @actMorningLight.
  ///
  /// In en, this message translates to:
  /// **'{n} minutes of daylight in the morning'**
  String actMorningLight(String n);

  /// No description provided for @actNoCaffeineLate.
  ///
  /// In en, this message translates to:
  /// **'No caffeine after 2 pm'**
  String get actNoCaffeineLate;

  /// No description provided for @actReadPages.
  ///
  /// In en, this message translates to:
  /// **'Read {n} pages'**
  String actReadPages(String n);

  /// No description provided for @actStudy.
  ///
  /// In en, this message translates to:
  /// **'Study for {n} minutes'**
  String actStudy(String n);

  /// No description provided for @actNewWords.
  ///
  /// In en, this message translates to:
  /// **'Learn {n} new words'**
  String actNewWords(String n);

  /// No description provided for @actLesson.
  ///
  /// In en, this message translates to:
  /// **'Take one lesson or watch one lecture'**
  String get actLesson;

  /// No description provided for @actTeachBack.
  ///
  /// In en, this message translates to:
  /// **'Explain what you learned to someone'**
  String get actTeachBack;

  /// No description provided for @actMeditate.
  ///
  /// In en, this message translates to:
  /// **'Meditate for {n} minutes'**
  String actMeditate(String n);

  /// No description provided for @actGratitude.
  ///
  /// In en, this message translates to:
  /// **'Write down {n} things you are grateful for'**
  String actGratitude(String n);

  /// No description provided for @actWalkOutside.
  ///
  /// In en, this message translates to:
  /// **'Walk outside for {n} minutes'**
  String actWalkOutside(String n);

  /// No description provided for @actJournal.
  ///
  /// In en, this message translates to:
  /// **'Write in your journal'**
  String get actJournal;

  /// No description provided for @actBreathing.
  ///
  /// In en, this message translates to:
  /// **'{n} minutes of slow breathing'**
  String actBreathing(String n);

  /// No description provided for @actStreak.
  ///
  /// In en, this message translates to:
  /// **'Complete your daily quest on {n} days'**
  String actStreak(String n);

  /// No description provided for @customStep.
  ///
  /// In en, this message translates to:
  /// **'{label}: {amount} {unit}'**
  String customStep(String label, String amount, String unit);

  /// No description provided for @progressOf.
  ///
  /// In en, this message translates to:
  /// **'{done} of {target}'**
  String progressOf(String done, String target);

  /// No description provided for @catFitness.
  ///
  /// In en, this message translates to:
  /// **'Get fitter'**
  String get catFitness;

  /// No description provided for @catFitnessBlurb.
  ///
  /// In en, this message translates to:
  /// **'Strength, running, steps and workouts'**
  String get catFitnessBlurb;

  /// No description provided for @catProductivity.
  ///
  /// In en, this message translates to:
  /// **'Be more productive'**
  String get catProductivity;

  /// No description provided for @catProductivityBlurb.
  ///
  /// In en, this message translates to:
  /// **'Focus, getting things done, planning'**
  String get catProductivityBlurb;

  /// No description provided for @catNutrition.
  ///
  /// In en, this message translates to:
  /// **'Eat healthier'**
  String get catNutrition;

  /// No description provided for @catNutritionBlurb.
  ///
  /// In en, this message translates to:
  /// **'Water, vegetables, fewer sweets'**
  String get catNutritionBlurb;

  /// No description provided for @catSleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep better'**
  String get catSleep;

  /// No description provided for @catSleepBlurb.
  ///
  /// In en, this message translates to:
  /// **'Enough sleep, a steady bedtime, calmer evenings'**
  String get catSleepBlurb;

  /// No description provided for @catLearning.
  ///
  /// In en, this message translates to:
  /// **'Learn something'**
  String get catLearning;

  /// No description provided for @catLearningBlurb.
  ///
  /// In en, this message translates to:
  /// **'Reading, a language, a new skill'**
  String get catLearningBlurb;

  /// No description provided for @catMindfulness.
  ///
  /// In en, this message translates to:
  /// **'Feel calmer'**
  String get catMindfulness;

  /// No description provided for @catMindfulnessBlurb.
  ///
  /// In en, this message translates to:
  /// **'Meditation, gratitude, time outside'**
  String get catMindfulnessBlurb;

  /// No description provided for @catCustom.
  ///
  /// In en, this message translates to:
  /// **'My own goal'**
  String get catCustom;

  /// No description provided for @catCustomBlurb.
  ///
  /// In en, this message translates to:
  /// **'Anything else: you choose the habits'**
  String get catCustomBlurb;

  /// No description provided for @qLevel.
  ///
  /// In en, this message translates to:
  /// **'Where are you starting from?'**
  String get qLevel;

  /// No description provided for @qTime.
  ///
  /// In en, this message translates to:
  /// **'How much time can you give it each day?'**
  String get qTime;

  /// No description provided for @qPushups.
  ///
  /// In en, this message translates to:
  /// **'How many push-ups can you do in a row?'**
  String get qPushups;

  /// No description provided for @qRunning.
  ///
  /// In en, this message translates to:
  /// **'What is the longest you have run lately?'**
  String get qRunning;

  /// No description provided for @qFocus.
  ///
  /// In en, this message translates to:
  /// **'What do you want more of?'**
  String get qFocus;

  /// No description provided for @qFocusNow.
  ///
  /// In en, this message translates to:
  /// **'How long can you focus without a break?'**
  String get qFocusNow;

  /// No description provided for @qStruggle.
  ///
  /// In en, this message translates to:
  /// **'What gets in the way most?'**
  String get qStruggle;

  /// No description provided for @qWaterNow.
  ///
  /// In en, this message translates to:
  /// **'How much water do you drink a day?'**
  String get qWaterNow;

  /// No description provided for @qVeggiesNow.
  ///
  /// In en, this message translates to:
  /// **'How many servings of vegetables a day?'**
  String get qVeggiesNow;

  /// No description provided for @qSleepNow.
  ///
  /// In en, this message translates to:
  /// **'How long do you usually sleep?'**
  String get qSleepNow;

  /// No description provided for @qReadNow.
  ///
  /// In en, this message translates to:
  /// **'How much do you read on a normal day?'**
  String get qReadNow;

  /// No description provided for @qKind.
  ///
  /// In en, this message translates to:
  /// **'What are you learning?'**
  String get qKind;

  /// No description provided for @qMeditateNow.
  ///
  /// In en, this message translates to:
  /// **'Do you meditate?'**
  String get qMeditateNow;

  /// No description provided for @optBeginner.
  ///
  /// In en, this message translates to:
  /// **'Just starting'**
  String get optBeginner;

  /// No description provided for @optSome.
  ///
  /// In en, this message translates to:
  /// **'Some experience'**
  String get optSome;

  /// No description provided for @optExperienced.
  ///
  /// In en, this message translates to:
  /// **'Experienced'**
  String get optExperienced;

  /// No description provided for @optMin10.
  ///
  /// In en, this message translates to:
  /// **'About 10 minutes'**
  String get optMin10;

  /// No description provided for @optMin20.
  ///
  /// In en, this message translates to:
  /// **'About 20 minutes'**
  String get optMin20;

  /// No description provided for @optMin40.
  ///
  /// In en, this message translates to:
  /// **'About 40 minutes'**
  String get optMin40;

  /// No description provided for @optMin60.
  ///
  /// In en, this message translates to:
  /// **'An hour or more'**
  String get optMin60;

  /// No description provided for @optP0.
  ///
  /// In en, this message translates to:
  /// **'Fewer than 5'**
  String get optP0;

  /// No description provided for @optP10.
  ///
  /// In en, this message translates to:
  /// **'5 to 15'**
  String get optP10;

  /// No description provided for @optP25.
  ///
  /// In en, this message translates to:
  /// **'15 to 30'**
  String get optP25;

  /// No description provided for @optP40.
  ///
  /// In en, this message translates to:
  /// **'More than 30'**
  String get optP40;

  /// No description provided for @optR0.
  ///
  /// In en, this message translates to:
  /// **'I don\'t run'**
  String get optR0;

  /// No description provided for @optR2.
  ///
  /// In en, this message translates to:
  /// **'Up to 2 km'**
  String get optR2;

  /// No description provided for @optR5.
  ///
  /// In en, this message translates to:
  /// **'2 to 5 km'**
  String get optR5;

  /// No description provided for @optR10.
  ///
  /// In en, this message translates to:
  /// **'More than 5 km'**
  String get optR10;

  /// No description provided for @optStrength.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get optStrength;

  /// No description provided for @optCardio.
  ///
  /// In en, this message translates to:
  /// **'Cardio and endurance'**
  String get optCardio;

  /// No description provided for @optMix.
  ///
  /// In en, this message translates to:
  /// **'A mix'**
  String get optMix;

  /// No description provided for @optF15.
  ///
  /// In en, this message translates to:
  /// **'About 15 minutes'**
  String get optF15;

  /// No description provided for @optF30.
  ///
  /// In en, this message translates to:
  /// **'About 30 minutes'**
  String get optF30;

  /// No description provided for @optF60.
  ///
  /// In en, this message translates to:
  /// **'An hour or more'**
  String get optF60;

  /// No description provided for @optProcrastination.
  ///
  /// In en, this message translates to:
  /// **'Putting things off'**
  String get optProcrastination;

  /// No description provided for @optDistraction.
  ///
  /// In en, this message translates to:
  /// **'Distractions and my phone'**
  String get optDistraction;

  /// No description provided for @optPlanning.
  ///
  /// In en, this message translates to:
  /// **'No plan for the day'**
  String get optPlanning;

  /// No description provided for @optW2.
  ///
  /// In en, this message translates to:
  /// **'1 to 3 glasses'**
  String get optW2;

  /// No description provided for @optW5.
  ///
  /// In en, this message translates to:
  /// **'4 to 6 glasses'**
  String get optW5;

  /// No description provided for @optW8.
  ///
  /// In en, this message translates to:
  /// **'7 or more'**
  String get optW8;

  /// No description provided for @optV0.
  ///
  /// In en, this message translates to:
  /// **'Hardly any'**
  String get optV0;

  /// No description provided for @optV2.
  ///
  /// In en, this message translates to:
  /// **'1 to 3'**
  String get optV2;

  /// No description provided for @optV4.
  ///
  /// In en, this message translates to:
  /// **'4 or more'**
  String get optV4;

  /// No description provided for @optSugar.
  ///
  /// In en, this message translates to:
  /// **'Sweets and sugary drinks'**
  String get optSugar;

  /// No description provided for @optSnacking.
  ///
  /// In en, this message translates to:
  /// **'Snacking'**
  String get optSnacking;

  /// No description provided for @optCooking.
  ///
  /// In en, this message translates to:
  /// **'Not cooking at home'**
  String get optCooking;

  /// No description provided for @optS5.
  ///
  /// In en, this message translates to:
  /// **'Under 6 hours'**
  String get optS5;

  /// No description provided for @optS6.
  ///
  /// In en, this message translates to:
  /// **'6 to 7 hours'**
  String get optS6;

  /// No description provided for @optS7.
  ///
  /// In en, this message translates to:
  /// **'7 to 8 hours'**
  String get optS7;

  /// No description provided for @optS8.
  ///
  /// In en, this message translates to:
  /// **'8 hours or more'**
  String get optS8;

  /// No description provided for @optLateBed.
  ///
  /// In en, this message translates to:
  /// **'Going to bed late'**
  String get optLateBed;

  /// No description provided for @optScreens.
  ///
  /// In en, this message translates to:
  /// **'Screens before bed'**
  String get optScreens;

  /// No description provided for @optMornings.
  ///
  /// In en, this message translates to:
  /// **'Hard mornings'**
  String get optMornings;

  /// No description provided for @optRead0.
  ///
  /// In en, this message translates to:
  /// **'Hardly at all'**
  String get optRead0;

  /// No description provided for @optRead10.
  ///
  /// In en, this message translates to:
  /// **'A few pages'**
  String get optRead10;

  /// No description provided for @optRead30.
  ///
  /// In en, this message translates to:
  /// **'A chapter or more'**
  String get optRead30;

  /// No description provided for @optLanguage.
  ///
  /// In en, this message translates to:
  /// **'A language'**
  String get optLanguage;

  /// No description provided for @optSkill.
  ///
  /// In en, this message translates to:
  /// **'A skill or a course'**
  String get optSkill;

  /// No description provided for @optBooks.
  ///
  /// In en, this message translates to:
  /// **'Reading more books'**
  String get optBooks;

  /// No description provided for @optNever.
  ///
  /// In en, this message translates to:
  /// **'Never tried'**
  String get optNever;

  /// No description provided for @optSometimes.
  ///
  /// In en, this message translates to:
  /// **'Sometimes'**
  String get optSometimes;

  /// No description provided for @optDaily.
  ///
  /// In en, this message translates to:
  /// **'Most days'**
  String get optDaily;

  /// No description provided for @optStress.
  ///
  /// In en, this message translates to:
  /// **'Stress'**
  String get optStress;

  /// No description provided for @optMood.
  ///
  /// In en, this message translates to:
  /// **'Low mood'**
  String get optMood;

  /// No description provided for @optOutdoors.
  ///
  /// In en, this message translates to:
  /// **'Too much time indoors'**
  String get optOutdoors;

  /// No description provided for @titleNovice.
  ///
  /// In en, this message translates to:
  /// **'Novice'**
  String get titleNovice;

  /// No description provided for @titleApprentice.
  ///
  /// In en, this message translates to:
  /// **'Apprentice'**
  String get titleApprentice;

  /// No description provided for @titleAdventurer.
  ///
  /// In en, this message translates to:
  /// **'Adventurer'**
  String get titleAdventurer;

  /// No description provided for @titlePathfinder.
  ///
  /// In en, this message translates to:
  /// **'Pathfinder'**
  String get titlePathfinder;

  /// No description provided for @titleVeteran.
  ///
  /// In en, this message translates to:
  /// **'Veteran'**
  String get titleVeteran;

  /// No description provided for @titleHero.
  ///
  /// In en, this message translates to:
  /// **'Hero'**
  String get titleHero;

  /// No description provided for @titleChampion.
  ///
  /// In en, this message translates to:
  /// **'Champion'**
  String get titleChampion;

  /// No description provided for @titleMaster.
  ///
  /// In en, this message translates to:
  /// **'Master'**
  String get titleMaster;

  /// No description provided for @titleLegend.
  ///
  /// In en, this message translates to:
  /// **'Legend'**
  String get titleLegend;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @addRest.
  ///
  /// In en, this message translates to:
  /// **'+{n} (the rest)'**
  String addRest(String n);

  /// No description provided for @amountDone.
  ///
  /// In en, this message translates to:
  /// **'How much did you do?'**
  String get amountDone;

  /// No description provided for @bestSoFar.
  ///
  /// In en, this message translates to:
  /// **'Your best so far'**
  String get bestSoFar;

  /// No description provided for @setTotal.
  ///
  /// In en, this message translates to:
  /// **'Set as total'**
  String get setTotal;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @turnOff.
  ///
  /// In en, this message translates to:
  /// **'Turn off'**
  String get turnOff;

  /// No description provided for @onward.
  ///
  /// In en, this message translates to:
  /// **'Onward!'**
  String get onward;

  /// No description provided for @couldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load your quests'**
  String get couldNotLoad;

  /// No description provided for @tabToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get tabToday;

  /// No description provided for @tabEpics.
  ///
  /// In en, this message translates to:
  /// **'Epics'**
  String get tabEpics;

  /// No description provided for @tabGoals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get tabGoals;

  /// No description provided for @tabHero.
  ///
  /// In en, this message translates to:
  /// **'Hero'**
  String get tabHero;

  /// No description provided for @dailyQuest.
  ///
  /// In en, this message translates to:
  /// **'Daily quest'**
  String get dailyQuest;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @missed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get missed;

  /// No description provided for @skippedToday.
  ///
  /// In en, this message translates to:
  /// **'Skipped today'**
  String get skippedToday;

  /// No description provided for @difficultyValue.
  ///
  /// In en, this message translates to:
  /// **'difficulty {d}×'**
  String difficultyValue(String d);

  /// No description provided for @daysLeft.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Last day} other{{n} days left}}'**
  String daysLeft(int n);

  /// No description provided for @endedOn.
  ///
  /// In en, this message translates to:
  /// **'Ended {day}'**
  String endedOn(String day);

  /// No description provided for @xpAmount.
  ///
  /// In en, this message translates to:
  /// **'+{n} XP'**
  String xpAmount(int n);

  /// No description provided for @goldAmount.
  ///
  /// In en, this message translates to:
  /// **'{n} gold'**
  String goldAmount(int n);

  /// No description provided for @logProgress.
  ///
  /// In en, this message translates to:
  /// **'Log progress'**
  String get logProgress;

  /// No description provided for @fromHealthConnect.
  ///
  /// In en, this message translates to:
  /// **'Filled from Health Connect when it is on'**
  String get fromHealthConnect;

  /// No description provided for @questComplete.
  ///
  /// In en, this message translates to:
  /// **'Quest complete!'**
  String get questComplete;

  /// No description provided for @epicComplete.
  ///
  /// In en, this message translates to:
  /// **'Epic quest complete!'**
  String get epicComplete;

  /// No description provided for @levelUp.
  ///
  /// In en, this message translates to:
  /// **'Level up! You reached level {n}'**
  String levelUp(int n);

  /// No description provided for @levelTitle.
  ///
  /// In en, this message translates to:
  /// **'Level {n} · {title}'**
  String levelTitle(int n, String title);

  /// No description provided for @levelShort.
  ///
  /// In en, this message translates to:
  /// **'Lvl {n}'**
  String levelShort(int n);

  /// No description provided for @xpToNext.
  ///
  /// In en, this message translates to:
  /// **'{have} / {need} XP to level {next}'**
  String xpToNext(int have, int need, int next);

  /// No description provided for @streakDays.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1-day streak} other{{n}-day streak}}'**
  String streakDays(int n);

  /// No description provided for @freezesHeld.
  ///
  /// In en, this message translates to:
  /// **'{n} streak {n, plural, =1{freeze} other{freezes}}'**
  String freezesHeld(int n);

  /// No description provided for @declineAction.
  ///
  /// In en, this message translates to:
  /// **'Decline quest'**
  String get declineAction;

  /// No description provided for @declineTitle.
  ///
  /// In en, this message translates to:
  /// **'Why decline it?'**
  String get declineTitle;

  /// No description provided for @declineFree.
  ///
  /// In en, this message translates to:
  /// **'Your first decline today is free.'**
  String get declineFree;

  /// No description provided for @declineCosts.
  ///
  /// In en, this message translates to:
  /// **'You already declined one today: this one costs {n} gold.'**
  String declineCosts(int n);

  /// No description provided for @declineTooHard.
  ///
  /// In en, this message translates to:
  /// **'Too hard'**
  String get declineTooHard;

  /// No description provided for @declineTooHardHint.
  ///
  /// In en, this message translates to:
  /// **'Get an easier quest. Future quests get easier too.'**
  String get declineTooHardHint;

  /// No description provided for @declineTooEasy.
  ///
  /// In en, this message translates to:
  /// **'Too easy'**
  String get declineTooEasy;

  /// No description provided for @declineTooEasyHint.
  ///
  /// In en, this message translates to:
  /// **'Get a harder quest. Future quests get harder too.'**
  String get declineTooEasyHint;

  /// No description provided for @declineDifferent.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get declineDifferent;

  /// No description provided for @declineDifferentHint.
  ///
  /// In en, this message translates to:
  /// **'Same difficulty, different activities.'**
  String get declineDifferentHint;

  /// No description provided for @declineNotToday.
  ///
  /// In en, this message translates to:
  /// **'Not today'**
  String get declineNotToday;

  /// No description provided for @declineNotTodayHint.
  ///
  /// In en, this message translates to:
  /// **'Skip this goal today. Back tomorrow.'**
  String get declineNotTodayHint;

  /// No description provided for @notEnoughGold.
  ///
  /// In en, this message translates to:
  /// **'Not enough gold yet. Complete quests to earn more.'**
  String get notEnoughGold;

  /// No description provided for @noMoreSwaps.
  ///
  /// In en, this message translates to:
  /// **'No more swaps for this goal today.'**
  String get noMoreSwaps;

  /// No description provided for @epicStreakTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete {n} daily quests within {days} days'**
  String epicStreakTitle(String n, int days);

  /// No description provided for @epicBestTitle.
  ///
  /// In en, this message translates to:
  /// **'In one day: {what}'**
  String epicBestTitle(String what);

  /// No description provided for @epicTotalTitle.
  ///
  /// In en, this message translates to:
  /// **'{what} in total, within {days} days'**
  String epicTotalTitle(String what, int days);

  /// No description provided for @epicOffered.
  ///
  /// In en, this message translates to:
  /// **'New epic quest · {goal}'**
  String epicOffered(String goal);

  /// No description provided for @epicAccepted.
  ///
  /// In en, this message translates to:
  /// **'Epic quest accepted. Your daily quests count towards it.'**
  String get epicAccepted;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @epicsRunning.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get epicsRunning;

  /// No description provided for @epicsFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get epicsFinished;

  /// No description provided for @noEpicsTitle.
  ///
  /// In en, this message translates to:
  /// **'No epic quests yet'**
  String get noEpicsTitle;

  /// No description provided for @noEpicsBody.
  ///
  /// In en, this message translates to:
  /// **'Complete a few daily quests and your goals will offer bigger challenges. You can also set your own.'**
  String get noEpicsBody;

  /// No description provided for @ownEpicTitle.
  ///
  /// In en, this message translates to:
  /// **'Own epic quest'**
  String get ownEpicTitle;

  /// No description provided for @ownEpicBody.
  ///
  /// In en, this message translates to:
  /// **'A big goal with a deadline, like \"Run a half marathon\" or \"Read 3 books\". Log progress whenever you make some.'**
  String get ownEpicBody;

  /// No description provided for @ownEpicName.
  ///
  /// In en, this message translates to:
  /// **'What is the quest?'**
  String get ownEpicName;

  /// No description provided for @ownEpicNameHint.
  ///
  /// In en, this message translates to:
  /// **'Read 3 books'**
  String get ownEpicNameHint;

  /// No description provided for @ownEpicAmount.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get ownEpicAmount;

  /// No description provided for @ownEpicUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get ownEpicUnit;

  /// No description provided for @ownEpicUnitHint.
  ///
  /// In en, this message translates to:
  /// **'books'**
  String get ownEpicUnitHint;

  /// No description provided for @ownEpicGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal it belongs to'**
  String get ownEpicGoal;

  /// No description provided for @ownEpicDays.
  ///
  /// In en, this message translates to:
  /// **'Time to finish'**
  String get ownEpicDays;

  /// No description provided for @ownEpicCreate.
  ///
  /// In en, this message translates to:
  /// **'Start the quest'**
  String get ownEpicCreate;

  /// No description provided for @daysCount.
  ///
  /// In en, this message translates to:
  /// **'{n} days'**
  String daysCount(int n);

  /// No description provided for @firstGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'What do you want to get better at?'**
  String get firstGoalTitle;

  /// No description provided for @firstGoalBody.
  ///
  /// In en, this message translates to:
  /// **'Pick a goal and answer a few questions. You get a daily quest sized for you, and it adapts as you go.'**
  String get firstGoalBody;

  /// No description provided for @chooseGoal.
  ///
  /// In en, this message translates to:
  /// **'Choose a goal'**
  String get chooseGoal;

  /// No description provided for @newGoal.
  ///
  /// In en, this message translates to:
  /// **'New goal'**
  String get newGoal;

  /// No description provided for @editGoal.
  ///
  /// In en, this message translates to:
  /// **'Edit goal'**
  String get editGoal;

  /// No description provided for @whatGoal.
  ///
  /// In en, this message translates to:
  /// **'What is your goal?'**
  String get whatGoal;

  /// No description provided for @whatGoalHint.
  ///
  /// In en, this message translates to:
  /// **'You can add more goals later.'**
  String get whatGoalHint;

  /// No description provided for @startQuesting.
  ///
  /// In en, this message translates to:
  /// **'Start questing'**
  String get startQuesting;

  /// No description provided for @goalName.
  ///
  /// In en, this message translates to:
  /// **'Name of the goal'**
  String get goalName;

  /// No description provided for @goalNameHint.
  ///
  /// In en, this message translates to:
  /// **'Play the guitar'**
  String get goalNameHint;

  /// No description provided for @yourHabits.
  ///
  /// In en, this message translates to:
  /// **'Your habits'**
  String get yourHabits;

  /// No description provided for @yourHabitsHint.
  ///
  /// In en, this message translates to:
  /// **'Quests are made from these. Add at least one.'**
  String get yourHabitsHint;

  /// No description provided for @addHabit.
  ///
  /// In en, this message translates to:
  /// **'Add a habit'**
  String get addHabit;

  /// No description provided for @editHabit.
  ///
  /// In en, this message translates to:
  /// **'Edit habit'**
  String get editHabit;

  /// No description provided for @habitName.
  ///
  /// In en, this message translates to:
  /// **'Habit'**
  String get habitName;

  /// No description provided for @habitNameHint.
  ///
  /// In en, this message translates to:
  /// **'Practise guitar'**
  String get habitNameHint;

  /// No description provided for @habitAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount (optional)'**
  String get habitAmount;

  /// No description provided for @habitAmountHint.
  ///
  /// In en, this message translates to:
  /// **'Leave empty for a yes/no habit'**
  String get habitAmountHint;

  /// No description provided for @habitUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get habitUnit;

  /// No description provided for @habitUnitHint.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get habitUnitHint;

  /// No description provided for @yesNoHabit.
  ///
  /// In en, this message translates to:
  /// **'Yes / no'**
  String get yesNoHabit;

  /// No description provided for @archivedGoals.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get archivedGoals;

  /// No description provided for @weekDone.
  ///
  /// In en, this message translates to:
  /// **'{done}/{made} this week'**
  String weekDone(int done, int made);

  /// No description provided for @editAnswers.
  ///
  /// In en, this message translates to:
  /// **'Change answers'**
  String get editAnswers;

  /// No description provided for @archiveGoal.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archiveGoal;

  /// No description provided for @unarchiveGoal.
  ///
  /// In en, this message translates to:
  /// **'Bring back'**
  String get unarchiveGoal;

  /// No description provided for @deleteGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this goal?'**
  String get deleteGoalTitle;

  /// No description provided for @deleteGoalBody.
  ///
  /// In en, this message translates to:
  /// **'Its quests are deleted too, with the XP and gold they earned. To keep them, archive the goal instead.'**
  String get deleteGoalBody;

  /// No description provided for @statQuestsDone.
  ///
  /// In en, this message translates to:
  /// **'Quests done'**
  String get statQuestsDone;

  /// No description provided for @statDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty now'**
  String get statDifficulty;

  /// No description provided for @statSince.
  ///
  /// In en, this message translates to:
  /// **'Since'**
  String get statSince;

  /// No description provided for @difficultyExplained.
  ///
  /// In en, this message translates to:
  /// **'Difficulty starts from your answers. Each completed quest raises it a little, quests left under half done lower it, and declining as too hard or too easy changes it right away.'**
  String get difficultyExplained;

  /// No description provided for @statDailies.
  ///
  /// In en, this message translates to:
  /// **'Daily quests'**
  String get statDailies;

  /// No description provided for @statEpics.
  ///
  /// In en, this message translates to:
  /// **'Epic quests'**
  String get statEpics;

  /// No description provided for @statBestStreak.
  ///
  /// In en, this message translates to:
  /// **'Best streak'**
  String get statBestStreak;

  /// No description provided for @statTotalXp.
  ///
  /// In en, this message translates to:
  /// **'Total XP'**
  String get statTotalXp;

  /// No description provided for @heroName.
  ///
  /// In en, this message translates to:
  /// **'Hero name'**
  String get heroName;

  /// No description provided for @shop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get shop;

  /// No description provided for @shopHint.
  ///
  /// In en, this message translates to:
  /// **'Spend gold here. Some items unlock for free as you level up.'**
  String get shopHint;

  /// No description provided for @streakFreeze.
  ///
  /// In en, this message translates to:
  /// **'Streak freeze'**
  String get streakFreeze;

  /// No description provided for @streakFreezeHint.
  ///
  /// In en, this message translates to:
  /// **'Keeps your streak through one missed day. Hold up to {n}.'**
  String streakFreezeHint(int n);

  /// No description provided for @emblems.
  ///
  /// In en, this message translates to:
  /// **'Emblems'**
  String get emblems;

  /// No description provided for @colors.
  ///
  /// In en, this message translates to:
  /// **'Colours'**
  String get colors;

  /// No description provided for @wear.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get wear;

  /// No description provided for @wearing.
  ///
  /// In en, this message translates to:
  /// **'In use'**
  String get wearing;

  /// No description provided for @buy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get buy;

  /// No description provided for @buyTitle.
  ///
  /// In en, this message translates to:
  /// **'Buy this?'**
  String get buyTitle;

  /// No description provided for @buyBody.
  ///
  /// In en, this message translates to:
  /// **'It costs {n} gold.'**
  String buyBody(int n);

  /// No description provided for @useHealth.
  ///
  /// In en, this message translates to:
  /// **'Use Health Connect'**
  String get useHealth;

  /// No description provided for @useHealthHint.
  ///
  /// In en, this message translates to:
  /// **'Fill steps, distance, workouts, sleep and water on their own, from ZT Fitness (turn on \"Save workouts and water to Health Connect\" in its settings), your watch or other apps. Read on this phone only.'**
  String get useHealthHint;

  /// No description provided for @healthUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Health Connect is not available on this phone.'**
  String get healthUnavailable;

  /// No description provided for @healthRefused.
  ///
  /// In en, this message translates to:
  /// **'Health Connect access was not allowed.'**
  String get healthRefused;

  /// No description provided for @dailyReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder'**
  String get dailyReminder;

  /// No description provided for @notificationsRefused.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off for ZT Quests in the phone settings.'**
  String get notificationsRefused;

  /// No description provided for @reminderChannel.
  ///
  /// In en, this message translates to:
  /// **'Daily quests'**
  String get reminderChannel;

  /// No description provided for @reminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Your quests are waiting'**
  String get reminderTitle;

  /// No description provided for @reminderBody.
  ///
  /// In en, this message translates to:
  /// **'Today\'s quests are ready. Keep your streak going!'**
  String get reminderBody;

  /// No description provided for @widgetDetails.
  ///
  /// In en, this message translates to:
  /// **'Show details on the home screen'**
  String get widgetDetails;

  /// No description provided for @widgetDetailsBody.
  ///
  /// In en, this message translates to:
  /// **'Off: the widgets show your level, gold, streak and how many steps are left. On: the steps of today\'s quests and your goal names are stored unencrypted on this phone for the home screen.'**
  String get widgetDetailsBody;

  /// No description provided for @widgetTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s quest'**
  String get widgetTodayTitle;

  /// No description provided for @widgetStepsDone.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} steps done'**
  String widgetStepsDone(String done, String total);

  /// No description provided for @widgetAllDone.
  ///
  /// In en, this message translates to:
  /// **'All done for today!'**
  String get widgetAllDone;

  /// No description provided for @widgetSignedOut.
  ///
  /// In en, this message translates to:
  /// **'Signed out'**
  String get widgetSignedOut;

  /// No description provided for @widgetOpenToSee.
  ///
  /// In en, this message translates to:
  /// **'Open ZT Quests to see your quests'**
  String get widgetOpenToSee;

  /// No description provided for @widgetNewDay.
  ///
  /// In en, this message translates to:
  /// **'New quests are ready. Open ZT Quests.'**
  String get widgetNewDay;

  /// No description provided for @widgetNoQuests.
  ///
  /// In en, this message translates to:
  /// **'No quests today. Add a goal in ZT Quests.'**
  String get widgetNoQuests;

  /// No description provided for @widgetCompleteStep.
  ///
  /// In en, this message translates to:
  /// **'Complete this step'**
  String get widgetCompleteStep;

  /// No description provided for @widgetLevel.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String widgetLevel(String level);

  /// No description provided for @widgetXp.
  ///
  /// In en, this message translates to:
  /// **'{xp} / {need} XP'**
  String widgetXp(String xp, String need);

  /// No description provided for @widgetGold.
  ///
  /// In en, this message translates to:
  /// **'{gold} gold'**
  String widgetGold(String gold);

  /// No description provided for @widgetStreak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get widgetStreak;

  /// No description provided for @widgetStreakWarn.
  ///
  /// In en, this message translates to:
  /// **'Do a quest today'**
  String get widgetStreakWarn;

  /// No description provided for @widgetStreakDone.
  ///
  /// In en, this message translates to:
  /// **'Done today'**
  String get widgetStreakDone;

  /// No description provided for @widgetNextStep.
  ///
  /// In en, this message translates to:
  /// **'Next step'**
  String get widgetNextStep;

  /// No description provided for @widgetStepsLeft.
  ///
  /// In en, this message translates to:
  /// **'Steps left: {count}'**
  String widgetStepsLeft(String count);

  /// No description provided for @widgetOpenApp.
  ///
  /// In en, this message translates to:
  /// **'Open ZT Quests'**
  String get widgetOpenApp;

  /// No description provided for @workoutAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Count your workouts'**
  String get workoutAccessTitle;

  /// No description provided for @workoutAccessBody.
  ///
  /// In en, this message translates to:
  /// **'Workouts from ZT Fitness or your watch can fill workout, run, stretching and walking quests. Health Connect shares them only when ZT Quests may also read calories burned. Read on this phone only.'**
  String get workoutAccessBody;

  /// No description provided for @workoutAccessAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get workoutAccessAllow;
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  Future<AppL10n> load(Locale locale) {
    return SynchronousFuture<AppL10n>(lookupAppL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'he'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}

AppL10n lookupAppL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppL10nEn();
    case 'he':
      return AppL10nHe();
  }

  throw FlutterError(
    'AppL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
