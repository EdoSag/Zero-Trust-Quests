import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart';

import '../engine/catalog.dart';

/// One day's activity from Health Connect: what ZT Fitness (with Health
/// write-back on), a watch or another fitness app recorded.
@immutable
class HealthDay {
  const HealthDay(this.values);
  final Map<HealthMetric, double> values;

  double? operator [](HealthMetric m) => values[m];
}

/// A glass (or cup) of water: 8 US fl oz, about 237 ml.
const litersPerGlass = 0.2365882365;

/// Whole glasses in [liters] of water, as water quests count them.
///
/// ZT Fitness logs water in 250 ml glasses, or 8 fl oz ones when set to
/// imperial units. Counting a glass as 8 fl oz makes one tap there one
/// glass here either way (a 250 ml glass is a little more than a glass, so
/// it never falls short). The small allowance keeps a full glass a full
/// glass after Health Connect's rounding.
double glassesFromLiters(double liters) =>
    liters <= 0 ? 0 : (liters / litersPerGlass + 0.02).floorToDouble();

/// One workout (exercise session) from Health Connect.
@immutable
class WorkoutSession {
  const WorkoutSession(this.type, this.from, this.to, {this.meters});

  final HealthWorkoutActivityType type;
  final DateTime from;
  final DateTime to;

  /// Distance Health Connect holds for the workout's time, if any.
  final double? meters;
}

const _runs = {
  HealthWorkoutActivityType.RUNNING,
  HealthWorkoutActivityType.RUNNING_TREADMILL,
  HealthWorkoutActivityType.WHEELCHAIR_RUN_PACE,
};

const _stretches = {
  HealthWorkoutActivityType.YOGA,
  HealthWorkoutActivityType.PILATES,
  HealthWorkoutActivityType.FLEXIBILITY,
  HealthWorkoutActivityType.MIND_AND_BODY,
};

const _walks = {
  HealthWorkoutActivityType.WALKING,
  HealthWorkoutActivityType.HIKING,
  HealthWorkoutActivityType.WHEELCHAIR_WALK_PACE,
};

/// What the day from [dayStart] to [dayEnd] gets from [sessions]: workout
/// minutes, kilometres run, runs without a distance, and minutes of
/// stretching and of walking.
///
/// Minutes count only the part inside the day, and a stretch of time two
/// apps both recorded (ZT Fitness and a watch) counts once. A run belongs
/// to the day it started; overlapping runs are one run, at the longest
/// distance either recorded (each sees all the distance in its time).
Map<HealthMetric, double> workoutValues(
  Iterable<WorkoutSession> sessions,
  DateTime dayStart,
  DateTime dayEnd,
) {
  final inDay = [
    for (final w in sessions)
      if (w.to.isAfter(dayStart) && w.from.isBefore(dayEnd)) w,
  ];
  double minutes(bool Function(WorkoutSession) which) {
    var total = Duration.zero;
    for (final (from, to, _) in _merged(inDay.where(which))) {
      final a = from.isBefore(dayStart) ? dayStart : from;
      final b = to.isAfter(dayEnd) ? dayEnd : to;
      if (b.isAfter(a)) total += b.difference(a);
    }
    return (total.inSeconds / 60).floorToDouble();
  }

  var km = 0.0;
  var withoutDistance = 0.0;
  for (final (_, _, group) in _merged(
    inDay.where((w) => _runs.contains(w.type) && !w.from.isBefore(dayStart)),
  )) {
    final meters = group.map((w) => w.meters ?? 0).reduce(math.max);
    if (meters > 0) {
      km += meters / 1000;
    } else {
      withoutDistance++;
    }
  }
  return {
    HealthMetric.workoutMinutes: minutes((_) => true),
    HealthMetric.stretchMinutes: minutes((w) => _stretches.contains(w.type)),
    HealthMetric.walkMinutes: minutes((w) => _walks.contains(w.type)),
    // Hundredths, so 2.999 km from a watch isn't short of 3.
    HealthMetric.runKm: (km * 100).roundToDouble() / 100,
    HealthMetric.runsWithoutDistance: withoutDistance,
  }..removeWhere((_, v) => v <= 0);
}

/// Overlapping (or touching) sessions joined: each group's start, end and
/// the sessions in it.
List<(DateTime, DateTime, List<WorkoutSession>)> _merged(
  Iterable<WorkoutSession> sessions,
) {
  final sorted = [
    for (final w in sessions)
      if (w.to.isAfter(w.from)) w,
  ]..sort((a, b) => a.from.compareTo(b.from));
  final out = <(DateTime, DateTime, List<WorkoutSession>)>[];
  for (final w in sorted) {
    if (out.isNotEmpty && !w.from.isAfter(out.last.$2)) {
      final (from, to, group) = out.last;
      out.last = (from, w.to.isAfter(to) ? w.to : to, [...group, w]);
    } else {
      out.add((w.from, w.to, [w]));
    }
  }
  return out;
}

/// Where activity data comes from. Read on the phone only; nothing is sent
/// anywhere except the quest progress it fills in, which is encrypted.
abstract class HealthSource {
  Future<bool> available();

  /// Asks for read access. False when refused or unavailable.
  Future<bool> requestAccess();

  /// Whether workouts can be read. Health Connect hands a workout over
  /// only with steps, distance and calories burned allowed too; people
  /// who turned Health Connect on before workouts counted weren't asked
  /// for calories.
  Future<bool> canReadWorkouts();

  Future<HealthDay> read(DateTime day);
}

/// No Health Connect (tests, iOS for now).
class NoHealthSource implements HealthSource {
  const NoHealthSource();
  @override
  Future<bool> available() async => false;
  @override
  Future<bool> requestAccess() async => false;
  @override
  Future<bool> canReadWorkouts() async => false;
  @override
  Future<HealthDay> read(DateTime day) async => const HealthDay({});
}

final healthSourceProvider = Provider<HealthSource>(
  (ref) => defaultTargetPlatform == TargetPlatform.android
      ? HealthConnectSource()
      : const NoHealthSource(),
);

/// Whether Health Connect lets this app read workouts (checked again each
/// time the Today tab asks).
final canReadWorkoutsProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(healthSourceProvider).canReadWorkouts(),
);

class HealthConnectSource implements HealthSource {
  final Health _health = Health();
  bool _configured = false;

  static const types = [
    HealthDataType.STEPS,
    HealthDataType.DISTANCE_DELTA,
    HealthDataType.WORKOUT,
    HealthDataType.TOTAL_CALORIES_BURNED,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.WATER,
  ];

  /// What reading a workout needs: the plugin adds up each workout's
  /// distance, calories and steps, and returns no workouts at all when
  /// any of them may not be read.
  static const workoutTypes = [
    HealthDataType.WORKOUT,
    HealthDataType.STEPS,
    HealthDataType.DISTANCE_DELTA,
    HealthDataType.TOTAL_CALORIES_BURNED,
  ];

  Future<void> _configure() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  @override
  Future<bool> available() async {
    try {
      await _configure();
      return await _health.getHealthConnectSdkStatus() ==
          HealthConnectSdkStatus.sdkAvailable;
    } on Object {
      return false;
    }
  }

  @override
  Future<bool> requestAccess() async {
    try {
      if (!await available()) return false;
      return await _health.requestAuthorization(
        types,
        permissions: [for (final _ in types) HealthDataAccess.READ],
      );
    } on Object {
      return false;
    }
  }

  @override
  Future<bool> canReadWorkouts() async {
    try {
      if (!await available()) return false;
      return await _health.hasPermissions(
            workoutTypes,
            permissions: [for (final _ in workoutTypes) HealthDataAccess.READ],
          ) ==
          true;
    } on Object {
      return false;
    }
  }

  @override
  Future<HealthDay> read(DateTime day) async {
    await _configure();
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final now = DateTime.now();
    final until = end.isAfter(now) ? now : end;
    final values = <HealthMetric, double>{};
    try {
      final steps = await _health.getTotalStepsInInterval(start, until);
      if (steps != null) values[HealthMetric.steps] = steps.toDouble();
    } on Object {
      // Not allowed or not recorded.
    }
    try {
      final points = _health.removeDuplicates(
        await _health.getHealthDataFromTypes(
          types: const [HealthDataType.WATER],
          startTime: start,
          endTime: until,
        ),
      );
      var liters = 0.0;
      for (final p in points) {
        if (p.type == HealthDataType.WATER) liters += _num(p);
      }
      final glasses = glassesFromLiters(liters);
      if (glasses > 0) values[HealthMetric.waterGlasses] = glasses;
    } on Object {
      // Not allowed or not recorded.
    }
    try {
      final points = _health.removeDuplicates(
        await _health.getHealthDataFromTypes(
          types: const [HealthDataType.WORKOUT],
          startTime: start,
          endTime: until,
        ),
      );
      values.addAll(
        workoutValues(
          [
            for (final p in points)
              if (p.value case final WorkoutHealthValue w)
                WorkoutSession(
                  w.workoutActivityType,
                  p.dateFrom,
                  p.dateTo,
                  meters: w.totalDistance?.toDouble(),
                ),
          ],
          start,
          // A workout saved with the time it was logged as its start ends
          // later today; it still counts in full.
          end,
        ),
      );
    } on Object {
      // Not allowed or not recorded.
    }
    try {
      // Last night: from 18:00 the day before to 14:00 on [day].
      final sleep = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.SLEEP_ASLEEP],
        startTime: start.subtract(const Duration(hours: 6)),
        endTime: start.add(const Duration(hours: 14)),
      );
      var minutes = 0.0;
      for (final p in _health.removeDuplicates(sleep)) {
        minutes += p.dateTo.difference(p.dateFrom).inMinutes;
      }
      if (minutes > 0) {
        values[HealthMetric.sleepHours] = (minutes / 30).floor() / 2;
      }
    } on Object {
      // Not allowed or not recorded.
    }
    return HealthDay(values);
  }

  static double _num(HealthDataPoint p) => switch (p.value) {
    NumericHealthValue(:final numericValue) => math.max(
      0,
      numericValue.toDouble(),
    ),
    _ => 0,
  };
}
