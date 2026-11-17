// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_l10n.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppL10nHe extends AppL10n {
  AppL10nHe([String locale = 'he']) : super(locale);

  @override
  String get appTitle => 'ZT Quests';

  @override
  String actPushups(String n) {
    return '$n שכיבות סמיכה';
  }

  @override
  String actSquats(String n) {
    return '$n סקוואטים';
  }

  @override
  String actSitups(String n) {
    return '$n כפיפות בטן';
  }

  @override
  String actLunges(String n) {
    return '$n מכרעים';
  }

  @override
  String actJumpingJacks(String n) {
    return '$n קפיצות פיסוק';
  }

  @override
  String actBurpees(String n) {
    return '$n ברפיז';
  }

  @override
  String actPlank(String n) {
    return 'פלאנק $n שניות';
  }

  @override
  String actRun(String n) {
    return 'ריצה של $n ק\"מ';
  }

  @override
  String actWalkSteps(String n) {
    return 'הליכה של $n צעדים';
  }

  @override
  String actWorkout(String n) {
    return 'אימון של $n דקות';
  }

  @override
  String actStretch(String n) {
    return 'מתיחות $n דקות';
  }

  @override
  String actDeepWork(String n) {
    return '$n דקות של עבודה ממוקדת';
  }

  @override
  String actPomodoros(String n) {
    return '$n פומודורו (בלוקים של 25 דקות ריכוז)';
  }

  @override
  String actTasksDone(String n) {
    return 'סיום $n משימות';
  }

  @override
  String get actPlanTomorrow => 'תכנון של מחר לפני השינה';

  @override
  String get actInboxZero => 'ריקון תיבת הדואר';

  @override
  String get actNoPhoneMorning => 'בלי טלפון בשעה הראשונה של היום';

  @override
  String get actTidyDesk => 'סידור שולחן העבודה';

  @override
  String actWater(String n) {
    return 'שתייה של $n כוסות מים';
  }

  @override
  String actVeggies(String n) {
    return '$n מנות ירקות';
  }

  @override
  String actFruit(String n) {
    return '$n פירות';
  }

  @override
  String get actHomeMeal => 'ארוחה מבושלת בבית';

  @override
  String get actNoSugaryDrinks => 'בלי משקאות ממותקים היום';

  @override
  String get actNoLateSnack => 'בלי נשנושים אחרי ארוחת הערב';

  @override
  String get actProtein => 'חלבון בכל ארוחה';

  @override
  String actSleepHours(String n) {
    return 'שינה של $n שעות';
  }

  @override
  String get actBedOnTime => 'במיטה בזמן השינה שקבעת';

  @override
  String actNoScreensBed(String n) {
    return 'בלי מסכים $n דקות לפני השינה';
  }

  @override
  String actMorningLight(String n) {
    return '$n דקות של אור יום בבוקר';
  }

  @override
  String get actNoCaffeineLate => 'בלי קפאין אחרי 14:00';

  @override
  String actReadPages(String n) {
    return 'קריאה של $n עמודים';
  }

  @override
  String actStudy(String n) {
    return 'לימוד של $n דקות';
  }

  @override
  String actNewWords(String n) {
    return 'לימוד $n מילים חדשות';
  }

  @override
  String get actLesson => 'שיעור אחד או הרצאה אחת';

  @override
  String get actTeachBack => 'הסבר למישהו מה למדת';

  @override
  String actMeditate(String n) {
    return 'מדיטציה של $n דקות';
  }

  @override
  String actGratitude(String n) {
    return 'כתיבת $n דברים שמגיעה עליהם תודה';
  }

  @override
  String actWalkOutside(String n) {
    return 'הליכה בחוץ $n דקות';
  }

  @override
  String get actJournal => 'כתיבה ביומן';

  @override
  String actBreathing(String n) {
    return '$n דקות של נשימות איטיות';
  }

  @override
  String actStreak(String n) {
    return 'השלמת המשימה היומית ב-$n ימים';
  }

  @override
  String customStep(String label, String amount, String unit) {
    return '$label: $amount $unit';
  }

  @override
  String progressOf(String done, String target) {
    return '$done מתוך $target';
  }

  @override
  String get catFitness => 'כושר';

  @override
  String get catFitnessBlurb => 'כוח, ריצה, צעדים ואימונים';

  @override
  String get catProductivity => 'פרודוקטיביות';

  @override
  String get catProductivityBlurb => 'ריכוז, ביצוע משימות ותכנון';

  @override
  String get catNutrition => 'תזונה בריאה';

  @override
  String get catNutritionBlurb => 'מים, ירקות ופחות מתוקים';

  @override
  String get catSleep => 'שינה טובה יותר';

  @override
  String get catSleepBlurb => 'מספיק שינה, שעת שינה קבועה וערבים רגועים';

  @override
  String get catLearning => 'לימוד';

  @override
  String get catLearningBlurb => 'קריאה, שפה או מיומנות חדשה';

  @override
  String get catMindfulness => 'רוגע ומיינדפולנס';

  @override
  String get catMindfulnessBlurb => 'מדיטציה, הכרת תודה וזמן בחוץ';

  @override
  String get catCustom => 'מטרה משלי';

  @override
  String get catCustomBlurb => 'כל דבר אחר: בוחרים את ההרגלים בעצמך';

  @override
  String get qLevel => 'מאיפה מתחילים?';

  @override
  String get qTime => 'כמה זמן ביום אפשר להקדיש לזה?';

  @override
  String get qPushups => 'כמה שכיבות סמיכה ברצף אפשר לעשות?';

  @override
  String get qRunning => 'מה המרחק הארוך ביותר שרצת לאחרונה?';

  @override
  String get qFocus => 'במה רוצים להתמקד?';

  @override
  String get qFocusNow => 'כמה זמן אפשר להתרכז בלי הפסקה?';

  @override
  String get qStruggle => 'מה הכי מפריע?';

  @override
  String get qWaterNow => 'כמה מים שותים ביום?';

  @override
  String get qVeggiesNow => 'כמה מנות ירקות ביום?';

  @override
  String get qSleepNow => 'כמה שעות ישנים בדרך כלל?';

  @override
  String get qReadNow => 'כמה קוראים ביום רגיל?';

  @override
  String get qKind => 'מה לומדים?';

  @override
  String get qMeditateNow => 'יש לך הרגל של מדיטציה?';

  @override
  String get optBeginner => 'רק מתחילים';

  @override
  String get optSome => 'יש קצת ניסיון';

  @override
  String get optExperienced => 'מנוסים';

  @override
  String get optMin10 => 'בערך 10 דקות';

  @override
  String get optMin20 => 'בערך 20 דקות';

  @override
  String get optMin40 => 'בערך 40 דקות';

  @override
  String get optMin60 => 'שעה או יותר';

  @override
  String get optP0 => 'פחות מ-5';

  @override
  String get optP10 => '5 עד 15';

  @override
  String get optP25 => '15 עד 30';

  @override
  String get optP40 => 'יותר מ-30';

  @override
  String get optR0 => 'לא רצים';

  @override
  String get optR2 => 'עד 2 ק\"מ';

  @override
  String get optR5 => '2 עד 5 ק\"מ';

  @override
  String get optR10 => 'יותר מ-5 ק\"מ';

  @override
  String get optStrength => 'כוח';

  @override
  String get optCardio => 'אירובי וסיבולת';

  @override
  String get optMix => 'שילוב';

  @override
  String get optF15 => 'בערך 15 דקות';

  @override
  String get optF30 => 'בערך 30 דקות';

  @override
  String get optF60 => 'שעה או יותר';

  @override
  String get optProcrastination => 'דחיינות';

  @override
  String get optDistraction => 'הסחות דעת והטלפון';

  @override
  String get optPlanning => 'אין תכנון ליום';

  @override
  String get optW2 => '1 עד 3 כוסות';

  @override
  String get optW5 => '4 עד 6 כוסות';

  @override
  String get optW8 => '7 או יותר';

  @override
  String get optV0 => 'כמעט בכלל לא';

  @override
  String get optV2 => '1 עד 3';

  @override
  String get optV4 => '4 או יותר';

  @override
  String get optSugar => 'מתוקים ומשקאות ממותקים';

  @override
  String get optSnacking => 'נשנושים';

  @override
  String get optCooking => 'לא מבשלים בבית';

  @override
  String get optS5 => 'פחות מ-6 שעות';

  @override
  String get optS6 => '6 עד 7 שעות';

  @override
  String get optS7 => '7 עד 8 שעות';

  @override
  String get optS8 => '8 שעות או יותר';

  @override
  String get optLateBed => 'הולכים לישון מאוחר';

  @override
  String get optScreens => 'מסכים לפני השינה';

  @override
  String get optMornings => 'בקרים קשים';

  @override
  String get optRead0 => 'כמעט בכלל לא';

  @override
  String get optRead10 => 'כמה עמודים';

  @override
  String get optRead30 => 'פרק או יותר';

  @override
  String get optLanguage => 'שפה';

  @override
  String get optSkill => 'מיומנות או קורס';

  @override
  String get optBooks => 'קריאת יותר ספרים';

  @override
  String get optNever => 'אף פעם לא ניסיתי';

  @override
  String get optSometimes => 'לפעמים';

  @override
  String get optDaily => 'ברוב הימים';

  @override
  String get optStress => 'לחץ';

  @override
  String get optMood => 'מצב רוח ירוד';

  @override
  String get optOutdoors => 'יותר מדי זמן בבית';

  @override
  String get titleNovice => 'מתחיל';

  @override
  String get titleApprentice => 'שוליה';

  @override
  String get titleAdventurer => 'הרפתקן';

  @override
  String get titlePathfinder => 'מגלה דרכים';

  @override
  String get titleVeteran => 'ותיק';

  @override
  String get titleHero => 'גיבור';

  @override
  String get titleChampion => 'אלוף';

  @override
  String get titleMaster => 'מאסטר';

  @override
  String get titleLegend => 'אגדה';

  @override
  String get accept => 'קבלה';

  @override
  String get add => 'הוספה';

  @override
  String addRest(String n) {
    return '+$n (כל השאר)';
  }

  @override
  String get amountDone => 'כמה עשית?';

  @override
  String get bestSoFar => 'השיא שלך עד עכשיו';

  @override
  String get setTotal => 'קביעה כסך הכול';

  @override
  String get save => 'שמירה';

  @override
  String get cancel => 'ביטול';

  @override
  String get delete => 'מחיקה';

  @override
  String get more => 'עוד';

  @override
  String get next => 'הבא';

  @override
  String get settings => 'הגדרות';

  @override
  String get notSet => 'לא הוגדר';

  @override
  String get off => 'כבוי';

  @override
  String get turnOff => 'כיבוי';

  @override
  String get onward => 'ממשיכים!';

  @override
  String get couldNotLoad => 'לא ניתן לטעון את המשימות';

  @override
  String get tabToday => 'היום';

  @override
  String get tabEpics => 'אפיות';

  @override
  String get tabGoals => 'מטרות';

  @override
  String get tabHero => 'גיבור';

  @override
  String get dailyQuest => 'משימה יומית';

  @override
  String get completed => 'הושלמה';

  @override
  String get missed => 'הוחמצה';

  @override
  String get skippedToday => 'דילגת היום';

  @override
  String difficultyValue(String d) {
    return 'קושי $d×';
  }

  @override
  String daysLeft(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'נשארו $n ימים',
      one: 'יום אחרון',
    );
    return '$_temp0';
  }

  @override
  String endedOn(String day) {
    return 'הסתיימה ב-$day';
  }

  @override
  String xpAmount(int n) {
    return '+$n XP';
  }

  @override
  String goldAmount(int n) {
    return '$n זהב';
  }

  @override
  String get logProgress => 'רישום התקדמות';

  @override
  String get fromHealthConnect => 'מתמלא מ-Health Connect כשהאפשרות פעילה';

  @override
  String get questComplete => 'המשימה הושלמה!';

  @override
  String get epicComplete => 'המשימה האפית הושלמה!';

  @override
  String levelUp(int n) {
    return 'עלית שלב! הגעת לשלב $n';
  }

  @override
  String levelTitle(int n, String title) {
    return 'שלב $n · $title';
  }

  @override
  String levelShort(int n) {
    return 'שלב $n';
  }

  @override
  String xpToNext(int have, int need, int next) {
    return '$have / $need XP לשלב $next';
  }

  @override
  String streakDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'רצף של $n ימים',
      one: 'רצף של יום אחד',
    );
    return '$_temp0';
  }

  @override
  String freezesHeld(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n הקפאות רצף',
      one: 'הקפאת רצף אחת',
    );
    return '$_temp0';
  }

  @override
  String get declineAction => 'דחיית המשימה';

  @override
  String get declineTitle => 'למה לדחות?';

  @override
  String get declineFree => 'הדחייה הראשונה היום בחינם.';

  @override
  String declineCosts(int n) {
    return 'כבר דחית משימה היום: הדחייה הזאת עולה $n זהב.';
  }

  @override
  String get declineTooHard => 'קשה מדי';

  @override
  String get declineTooHardHint =>
      'משימה קלה יותר, וגם המשימות הבאות יהיו קלות יותר.';

  @override
  String get declineTooEasy => 'קל מדי';

  @override
  String get declineTooEasyHint =>
      'משימה קשה יותר, וגם המשימות הבאות יהיו קשות יותר.';

  @override
  String get declineDifferent => 'משהו אחר';

  @override
  String get declineDifferentHint => 'אותו קושי, פעילויות אחרות.';

  @override
  String get declineNotToday => 'לא היום';

  @override
  String get declineNotTodayHint => 'דילוג על המטרה הזאת היום. חוזרת מחר.';

  @override
  String get notEnoughGold =>
      'אין מספיק זהב עדיין. משימות שמושלמות מביאות עוד.';

  @override
  String get noMoreSwaps => 'אין עוד החלפות למטרה הזאת היום.';

  @override
  String epicStreakTitle(String n, int days) {
    return 'השלמת $n משימות יומיות בתוך $days ימים';
  }

  @override
  String epicBestTitle(String what) {
    return 'ביום אחד: $what';
  }

  @override
  String epicTotalTitle(String what, int days) {
    return '$what בסך הכול, בתוך $days ימים';
  }

  @override
  String epicOffered(String goal) {
    return 'משימה אפית חדשה · $goal';
  }

  @override
  String get epicAccepted => 'המשימה האפית התקבלה. המשימות היומיות נספרות בה.';

  @override
  String get notNow => 'לא עכשיו';

  @override
  String get epicsRunning => 'בתהליך';

  @override
  String get epicsFinished => 'הסתיימו';

  @override
  String get noEpicsTitle => 'אין עדיין משימות אפיות';

  @override
  String get noEpicsBody =>
      'אחרי כמה משימות יומיות, המטרות שלך יציעו אתגרים גדולים יותר. אפשר גם ליצור אתגר משלך.';

  @override
  String get ownEpicTitle => 'משימה אפית משלי';

  @override
  String get ownEpicBody =>
      'מטרה גדולה עם תאריך יעד, כמו \"לרוץ חצי מרתון\" או \"לקרוא 3 ספרים\". רושמים התקדמות בכל פעם שיש.';

  @override
  String get ownEpicName => 'מה המשימה?';

  @override
  String get ownEpicNameHint => 'לקרוא 3 ספרים';

  @override
  String get ownEpicAmount => 'יעד';

  @override
  String get ownEpicUnit => 'יחידה';

  @override
  String get ownEpicUnitHint => 'ספרים';

  @override
  String get ownEpicGoal => 'המטרה שהיא שייכת אליה';

  @override
  String get ownEpicDays => 'זמן לסיום';

  @override
  String get ownEpicCreate => 'התחלת המשימה';

  @override
  String daysCount(int n) {
    return '$n ימים';
  }

  @override
  String get firstGoalTitle => 'במה רוצים להשתפר?';

  @override
  String get firstGoalBody =>
      'בוחרים מטרה ועונים על כמה שאלות. מקבלים משימה יומית שמותאמת לך ומשתנה לפי ההתקדמות.';

  @override
  String get chooseGoal => 'בחירת מטרה';

  @override
  String get newGoal => 'מטרה חדשה';

  @override
  String get editGoal => 'עריכת מטרה';

  @override
  String get whatGoal => 'מה המטרה?';

  @override
  String get whatGoalHint => 'אפשר להוסיף עוד מטרות אחר כך.';

  @override
  String get startQuesting => 'יוצאים לדרך';

  @override
  String get goalName => 'שם המטרה';

  @override
  String get goalNameHint => 'לנגן בגיטרה';

  @override
  String get yourHabits => 'ההרגלים שלך';

  @override
  String get yourHabitsHint => 'המשימות נבנות מהם. צריך להוסיף לפחות אחד.';

  @override
  String get addHabit => 'הוספת הרגל';

  @override
  String get editHabit => 'עריכת הרגל';

  @override
  String get habitName => 'הרגל';

  @override
  String get habitNameHint => 'תרגול גיטרה';

  @override
  String get habitAmount => 'כמות (לא חובה)';

  @override
  String get habitAmountHint => 'משאירים ריק להרגל של כן/לא';

  @override
  String get habitUnit => 'יחידה';

  @override
  String get habitUnitHint => 'דקות';

  @override
  String get yesNoHabit => 'כן / לא';

  @override
  String get archivedGoals => 'בארכיון';

  @override
  String weekDone(int done, int made) {
    return '$done/$made השבוע';
  }

  @override
  String get editAnswers => 'שינוי התשובות';

  @override
  String get archiveGoal => 'העברה לארכיון';

  @override
  String get unarchiveGoal => 'החזרה מהארכיון';

  @override
  String get deleteGoalTitle => 'למחוק את המטרה?';

  @override
  String get deleteGoalBody =>
      'גם המשימות שלה יימחקו, יחד עם ה-XP והזהב שהרווחו. כדי לשמור אותם, אפשר להעביר את המטרה לארכיון.';

  @override
  String get statQuestsDone => 'משימות שהושלמו';

  @override
  String get statDifficulty => 'קושי נוכחי';

  @override
  String get statSince => 'מאז';

  @override
  String get difficultyExplained =>
      'הקושי מתחיל מהתשובות שלך. כל משימה שהושלמה מעלה אותו קצת, משימות שבוצעו פחות מחצי מורידות אותו, ודחייה כ\"קשה מדי\" או \"קל מדי\" משנה אותו מיד.';

  @override
  String get statDailies => 'משימות יומיות';

  @override
  String get statEpics => 'משימות אפיות';

  @override
  String get statBestStreak => 'הרצף הכי ארוך';

  @override
  String get statTotalXp => 'סך הכול XP';

  @override
  String get heroName => 'שם הגיבור';

  @override
  String get shop => 'חנות';

  @override
  String get shopHint =>
      'כאן משתמשים בזהב. חלק מהפריטים נפתחים בחינם כשעולים שלב.';

  @override
  String get streakFreeze => 'הקפאת רצף';

  @override
  String streakFreezeHint(int n) {
    return 'שומרת על הרצף ביום אחד שהוחמץ. אפשר להחזיק עד $n.';
  }

  @override
  String get emblems => 'סמלים';

  @override
  String get colors => 'צבעים';

  @override
  String get wear => 'בחירה';

  @override
  String get wearing => 'בשימוש';

  @override
  String get buy => 'קנייה';

  @override
  String get buyTitle => 'לקנות?';

  @override
  String buyBody(int n) {
    return 'זה עולה $n זהב.';
  }

  @override
  String get useHealth => 'שימוש ב-Health Connect';

  @override
  String get useHealthHint =>
      'מילוי אוטומטי של צעדים, מרחק, אימונים, שינה ומים מ-ZT Fitness (כשהכתיבה ל-Health פעילה), מהשעון או מאפליקציות אחרות. נקרא רק בטלפון הזה.';

  @override
  String get healthUnavailable => 'Health Connect לא זמין בטלפון הזה.';

  @override
  String get healthRefused => 'לא ניתנה גישה ל-Health Connect.';

  @override
  String get dailyReminder => 'תזכורת יומית';

  @override
  String get notificationsRefused =>
      'ההתראות של ZT Quests כבויות בהגדרות הטלפון.';

  @override
  String get reminderChannel => 'משימות יומיות';

  @override
  String get reminderTitle => 'המשימות שלך מחכות';

  @override
  String get reminderBody => 'המשימות של היום מוכנות. ממשיכים את הרצף!';
}
