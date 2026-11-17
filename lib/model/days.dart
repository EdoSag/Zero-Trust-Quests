/// Days are local calendar dates kept as `yyyy-MM-dd` strings, so a quest
/// for "Tuesday" stays Tuesday's when the phone changes time zone.
library;

String dayKey(DateTime t) =>
    '${t.year.toString().padLeft(4, '0')}-'
    '${t.month.toString().padLeft(2, '0')}-'
    '${t.day.toString().padLeft(2, '0')}';

DateTime dayOf(String key) {
  final p = key.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

/// [key] moved by [days] (negative goes back).
String addDays(String key, int days) {
  final d = dayOf(key);
  return dayKey(DateTime(d.year, d.month, d.day + days));
}

/// Whole days from [from] to [to] (positive when [to] is later).
int daysBetween(String from, String to) {
  final a = dayOf(from);
  final b = dayOf(to);
  return DateTime.utc(
    b.year,
    b.month,
    b.day,
  ).difference(DateTime.utc(a.year, a.month, a.day)).inDays;
}

String today() => dayKey(DateTime.now());
