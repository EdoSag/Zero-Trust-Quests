import '../model/goal.dart';
import '../model/quest.dart';

/// How an activity is counted.
enum Unit {
  reps,
  seconds,
  minutes,
  hours,
  km,
  steps,
  glasses,
  servings,
  pages,
  count,
  check,
}

/// Health Connect values that can fill a step on their own.
enum HealthMetric {
  steps,

  /// Kilometres run in running workouts (walks and rides don't count).
  runKm,

  /// Running workouts saved without a distance (logged by hand in ZT
  /// Fitness): each one finishes the day's run.
  runsWithoutDistance,

  /// Minutes of any workout.
  workoutMinutes,

  /// Minutes of yoga, pilates and stretching workouts.
  stretchMinutes,

  /// Minutes of walking and hiking workouts.
  walkMinutes,
  sleepHours,
  waterGlasses,
}

/// One thing a quest can ask for. [base] is the amount for someone who
/// answered the middle options, at difficulty 1.
class Activity {
  const Activity(
    this.id,
    this.category,
    this.unit,
    this.base, {
    this.round = 1,
    this.min = 1,
    this.max = 100000,
    this.health,
    this.finishedBy,
  });

  final String id;
  final GoalCategory category;
  final Unit unit;
  final double base;

  /// Amounts are rounded to a multiple of this.
  final double round;
  final double min;
  final double max;
  final HealthMetric? health;

  /// A Health Connect count that finishes a daily step on its own (a run
  /// logged without a distance still counts as the day's run).
  final HealthMetric? finishedBy;

  bool get isCheck => unit == Unit.check;
}

const _f = GoalCategory.fitness;
const _p = GoalCategory.productivity;
const _n = GoalCategory.nutrition;
const _s = GoalCategory.sleep;
const _l = GoalCategory.learning;
const _m = GoalCategory.mindfulness;

const activities = <Activity>[
  // Fitness
  Activity('pushups', _f, Unit.reps, 15, min: 3, max: 200),
  Activity('squats', _f, Unit.reps, 20, min: 5, max: 300),
  Activity('situps', _f, Unit.reps, 20, min: 5, max: 300),
  Activity('lunges', _f, Unit.reps, 16, round: 2, min: 4, max: 200),
  Activity('jumpingJacks', _f, Unit.reps, 30, round: 5, min: 10, max: 500),
  Activity('burpees', _f, Unit.reps, 8, min: 3, max: 100),
  Activity('plank', _f, Unit.seconds, 45, round: 5, min: 15, max: 600),
  Activity(
    'run',
    _f,
    Unit.km,
    2,
    round: 0.5,
    min: 0.5,
    max: 42,
    health: HealthMetric.runKm,
    finishedBy: HealthMetric.runsWithoutDistance,
  ),
  Activity(
    'walkSteps',
    _f,
    Unit.steps,
    7000,
    round: 500,
    min: 2000,
    max: 30000,
    health: HealthMetric.steps,
  ),
  Activity(
    'workout',
    _f,
    Unit.minutes,
    20,
    round: 5,
    min: 10,
    max: 120,
    health: HealthMetric.workoutMinutes,
  ),
  Activity(
    'stretch',
    _f,
    Unit.minutes,
    10,
    round: 5,
    min: 5,
    max: 45,
    health: HealthMetric.stretchMinutes,
  ),
  // Productivity
  Activity('deepWork', _p, Unit.minutes, 45, round: 5, min: 15, max: 240),
  Activity('pomodoros', _p, Unit.count, 3, min: 1, max: 12),
  Activity('tasksDone', _p, Unit.count, 3, min: 1, max: 15),
  Activity('planTomorrow', _p, Unit.check, 1),
  Activity('inboxZero', _p, Unit.check, 1),
  Activity('noPhoneMorning', _p, Unit.check, 1),
  Activity('tidyDesk', _p, Unit.check, 1),
  // Nutrition
  Activity(
    'water',
    _n,
    Unit.glasses,
    6,
    min: 3,
    max: 12,
    health: HealthMetric.waterGlasses,
  ),
  Activity('veggies', _n, Unit.servings, 3, min: 1, max: 8),
  Activity('fruit', _n, Unit.servings, 2, min: 1, max: 5),
  Activity('homeMeal', _n, Unit.check, 1),
  Activity('noSugaryDrinks', _n, Unit.check, 1),
  Activity('noLateSnack', _n, Unit.check, 1),
  Activity('protein', _n, Unit.check, 1),
  // Sleep
  Activity(
    'sleepHours',
    _s,
    Unit.hours,
    7,
    round: 0.5,
    min: 6,
    max: 9,
    health: HealthMetric.sleepHours,
  ),
  Activity('bedOnTime', _s, Unit.check, 1),
  Activity('noScreensBed', _s, Unit.minutes, 30, round: 15, min: 15, max: 90),
  Activity('morningLight', _s, Unit.minutes, 10, round: 5, min: 5, max: 30),
  Activity('noCaffeineLate', _s, Unit.check, 1),
  // Learning
  Activity('readPages', _l, Unit.pages, 15, round: 5, min: 5, max: 100),
  Activity('study', _l, Unit.minutes, 25, round: 5, min: 10, max: 180),
  Activity('newWords', _l, Unit.count, 5, min: 3, max: 30),
  Activity('lesson', _l, Unit.check, 1),
  Activity('teachBack', _l, Unit.check, 1),
  // Mindfulness
  Activity('meditate', _m, Unit.minutes, 8, round: 1, min: 3, max: 60),
  Activity('gratitude', _m, Unit.count, 3, min: 1, max: 10),
  Activity(
    'walkOutside',
    _m,
    Unit.minutes,
    20,
    round: 5,
    min: 10,
    max: 90,
    health: HealthMetric.walkMinutes,
  ),
  Activity('journal', _m, Unit.check, 1),
  Activity('breathing', _m, Unit.minutes, 3, min: 2, max: 20),
];

final Map<String, Activity> activityById = {
  for (final a in activities) a.id: a,
};

/// One answer to a set-up question, and what it changes.
class Option {
  const Option(
    this.id, {
    this.scale = 1,
    this.bases = const {},
    this.exclude = const {},
    this.prefer = const {},
    this.steps,
  });

  final String id;

  /// Multiplies every amount of the goal.
  final double scale;

  /// Starting amounts for single activities, before [scale].
  final Map<String, double> bases;
  final Set<String> exclude;

  /// Activity id -> weight; picked more (or, below 1, less) often.
  final Map<String, double> prefer;

  /// Steps in a daily quest (from the time-per-day question).
  final int? steps;
}

class Question {
  const Question(this.id, this.options, {this.initial});

  final String id;
  final List<Option> options;

  /// The option picked if the user skips the question.
  final String? initial;
}

const _level = Question('level', [
  Option('beginner', scale: 0.6),
  Option('some', scale: 1),
  Option('experienced', scale: 1.5),
], initial: 'some');

const _time = Question('time', [
  Option('min10', scale: 0.8, steps: 1),
  Option('min20', steps: 2),
  Option('min40', steps: 3),
  Option('min60', scale: 1.2, steps: 3),
], initial: 'min20');

/// The questions asked when a goal of each category is set up, in order.
const questionsFor = <GoalCategory, List<Question>>{
  GoalCategory.fitness: [
    _level,
    Question('pushups', [
      Option('p0', bases: {'pushups': 3, 'burpees': 4}),
      Option('p10', bases: {'pushups': 6}),
      Option('p25', bases: {'pushups': 12}),
      Option('p40', bases: {'pushups': 20, 'burpees': 12}),
    ], initial: 'p10'),
    Question('running', [
      Option('r0', bases: {'run': 1}, prefer: {'run': 0.4, 'walkSteps': 2}),
      Option('r2', bases: {'run': 1.5}),
      Option('r5', bases: {'run': 2.5}, prefer: {'run': 1.5}),
      Option('r10', bases: {'run': 4}, prefer: {'run': 2}),
    ], initial: 'r2'),
    Question('focus', [
      Option(
        'strength',
        prefer: {
          'pushups': 2,
          'squats': 2,
          'situps': 1.5,
          'lunges': 1.5,
          'plank': 1.5,
          'run': 0.4,
          'walkSteps': 0.5,
        },
      ),
      Option(
        'cardio',
        prefer: {
          'run': 2.5,
          'walkSteps': 2,
          'jumpingJacks': 1.5,
          'burpees': 1.5,
          'workout': 1.5,
        },
      ),
      Option('mix'),
    ], initial: 'mix'),
    _time,
  ],
  GoalCategory.productivity: [
    Question('focusNow', [
      Option('f15', bases: {'deepWork': 20, 'pomodoros': 2}),
      Option('f30', bases: {'deepWork': 35}),
      Option('f60', bases: {'deepWork': 60, 'pomodoros': 4}),
    ], initial: 'f30'),
    Question('struggle', [
      Option('procrastination', prefer: {'tasksDone': 2, 'pomodoros': 2}),
      Option('distraction', prefer: {'noPhoneMorning': 2.5, 'deepWork': 2}),
      Option(
        'planning',
        prefer: {'planTomorrow': 2.5, 'inboxZero': 1.5, 'tidyDesk': 1.5},
      ),
    ], initial: 'procrastination'),
    _time,
  ],
  GoalCategory.nutrition: [
    Question('waterNow', [
      Option('w2', bases: {'water': 4}),
      Option('w5', bases: {'water': 6}),
      Option('w8', bases: {'water': 8}),
    ], initial: 'w5'),
    Question('veggiesNow', [
      Option('v0', bases: {'veggies': 1, 'fruit': 1}),
      Option('v2', bases: {'veggies': 2}),
      Option('v4', bases: {'veggies': 4, 'fruit': 3}),
    ], initial: 'v2'),
    Question('struggle', [
      Option('sugar', prefer: {'noSugaryDrinks': 2.5, 'fruit': 1.5}),
      Option('snacking', prefer: {'noLateSnack': 2.5, 'protein': 1.5}),
      Option('cooking', prefer: {'homeMeal': 2.5, 'veggies': 1.5}),
    ], initial: 'sugar'),
    _time,
  ],
  GoalCategory.sleep: [
    Question('sleepNow', [
      Option('s5', bases: {'sleepHours': 6.5}),
      Option('s6', bases: {'sleepHours': 7}),
      Option('s7', bases: {'sleepHours': 7.5}),
      Option('s8', bases: {'sleepHours': 8}),
    ], initial: 's6'),
    Question('struggle', [
      Option('lateBed', prefer: {'bedOnTime': 2.5, 'noCaffeineLate': 1.5}),
      Option('screens', prefer: {'noScreensBed': 2.5}),
      Option('mornings', prefer: {'morningLight': 2.5}),
    ], initial: 'lateBed'),
    _time,
  ],
  GoalCategory.learning: [
    _level,
    Question('readNow', [
      Option('read0', bases: {'readPages': 5}, prefer: {'readPages': 0.7}),
      Option('read10', bases: {'readPages': 10}),
      Option('read30', bases: {'readPages': 25}, prefer: {'readPages': 2}),
    ], initial: 'read10'),
    Question('kind', [
      Option('language', prefer: {'newWords': 3, 'study': 1.5}),
      Option('skill', prefer: {'study': 2, 'lesson': 2, 'teachBack': 1.5}),
      Option('books', prefer: {'readPages': 3}),
    ], initial: 'skill'),
    _time,
  ],
  GoalCategory.mindfulness: [
    Question('meditateNow', [
      Option('never', bases: {'meditate': 3, 'breathing': 2}),
      Option('sometimes', bases: {'meditate': 8}),
      Option('daily', bases: {'meditate': 15}, prefer: {'meditate': 2}),
    ], initial: 'sometimes'),
    Question('struggle', [
      Option('stress', prefer: {'breathing': 2, 'meditate': 1.5}),
      Option('mood', prefer: {'gratitude': 2, 'journal': 1.5}),
      Option('outdoors', prefer: {'walkOutside': 2.5}),
    ], initial: 'stress'),
    _time,
  ],
  GoalCategory.custom: [_time],
};

/// The options picked for [goal], with skipped questions on their default.
List<Option> chosenOptions(Goal goal) => [
  for (final q in questionsFor[goal.category] ?? const <Question>[])
    q.options.firstWhere(
      (o) => o.id == goal.answers[q.id],
      orElse: () => q.options.firstWhere(
        (o) => o.id == q.initial,
        orElse: () => q.options.first,
      ),
    ),
];

/// An epic quest a goal can offer once a few daily quests are done.
class EpicTemplate {
  const EpicTemplate(
    this.id,
    this.category,
    this.mode,
    this.days, {
    this.activity,
    this.factor = 1,
    this.count = 0,
    this.minimum = 0,
  });

  final String id;
  final GoalCategory category;
  final EpicMode mode;

  /// Days to finish it.
  final int days;

  /// Best and total epics: the activity counted.
  final String? activity;

  /// Target = the activity's daily amount x [factor].
  final double factor;

  /// Streak epics: days with a completed daily quest.
  final int count;
  final double minimum;
}

const epicTemplates = <EpicTemplate>[
  EpicTemplate(
    'longRun',
    _f,
    EpicMode.best,
    21,
    activity: 'run',
    factor: 2.5,
    minimum: 3,
  ),
  EpicTemplate(
    'pushupTotal',
    _f,
    EpicMode.total,
    14,
    activity: 'pushups',
    factor: 15,
  ),
  EpicTemplate(
    'stepsWeek',
    _f,
    EpicMode.total,
    7,
    activity: 'walkSteps',
    factor: 7,
  ),
  EpicTemplate('fitStreak', _f, EpicMode.streak, 10, count: 7),
  EpicTemplate(
    'deepWorkTotal',
    _p,
    EpicMode.total,
    14,
    activity: 'deepWork',
    factor: 10,
  ),
  EpicTemplate('prodStreak', _p, EpicMode.streak, 10, count: 7),
  EpicTemplate('waterStreak', _n, EpicMode.streak, 10, count: 7),
  EpicTemplate(
    'veggieTotal',
    _n,
    EpicMode.total,
    14,
    activity: 'veggies',
    factor: 12,
  ),
  EpicTemplate('sleepStreak', _s, EpicMode.streak, 10, count: 7),
  EpicTemplate(
    'pagesTotal',
    _l,
    EpicMode.total,
    14,
    activity: 'readPages',
    factor: 12,
  ),
  EpicTemplate('learnStreak', _l, EpicMode.streak, 10, count: 7),
  EpicTemplate(
    'meditateTotal',
    _m,
    EpicMode.total,
    14,
    activity: 'meditate',
    factor: 10,
  ),
  EpicTemplate('calmStreak', _m, EpicMode.streak, 10, count: 7),
  EpicTemplate(
    'customStreak',
    GoalCategory.custom,
    EpicMode.streak,
    10,
    count: 7,
  ),
];
