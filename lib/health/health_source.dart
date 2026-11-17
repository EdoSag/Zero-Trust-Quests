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

/// Where activity data comes from. Read on the phone only; nothing is sent
/// anywhere except the quest progress it fills in, which is encrypted.
abstract class HealthSource {
  Future<bool> available();

  /// Asks for read access. False when refused or unavailable.
  Future<bool> requestAccess();

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
  Future<HealthDay> read(DateTime day) async => const HealthDay({});
}

final healthSourceProvider = Provider<HealthSource>(
  (ref) => defaultTargetPlatform == TargetPlatform.android
      ? HealthConnectSource()
      : const NoHealthSource(),
);

class HealthConnectSource implements HealthSource {
  final Health _health = Health();
  bool _configured = false;

  static const types = [
    HealthDataType.STEPS,
    HealthDataType.DISTANCE_DELTA,
    HealthDataType.WORKOUT,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.WATER,
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
          types: const [
            HealthDataType.DISTANCE_DELTA,
            HealthDataType.WORKOUT,
            HealthDataType.WATER,
          ],
          startTime: start,
          endTime: until,
        ),
      );
      var meters = 0.0;
      var workoutMinutes = 0.0;
      var liters = 0.0;
      for (final p in points) {
        switch (p.type) {
          case HealthDataType.DISTANCE_DELTA:
            meters += _num(p);
          case HealthDataType.WORKOUT:
            workoutMinutes += p.dateTo.difference(p.dateFrom).inSeconds / 60;
          case HealthDataType.WATER:
            liters += _num(p);
          default:
            break;
        }
      }
      if (meters > 0) values[HealthMetric.distanceKm] = meters / 1000;
      if (workoutMinutes > 0) {
        values[HealthMetric.workoutMinutes] = workoutMinutes.floorToDouble();
      }
      // A glass is 250 ml.
      if (liters > 0) {
        values[HealthMetric.waterGlasses] = (liters * 4).floorToDouble();
      }
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
