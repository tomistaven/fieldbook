import 'package:intl/intl.dart';

/// Short, human-readable date labels relative to today.
class DateLabels {
  DateLabels._();

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// "Today", "Tomorrow", "Yesterday", "Mon 3 Nov" or "3 Nov 2027".
  static String relativeDay(DateTime date, {DateTime? now}) {
    final today = _day(now ?? DateTime.now());
    final diff = _day(date).difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (date.year == today.year) return DateFormat('EEE d MMM').format(date);
    return DateFormat('d MMM y').format(date);
  }

  /// Time for today's entries, otherwise the date.
  static String timestamp(DateTime date, {DateTime? now}) {
    final today = _day(now ?? DateTime.now());
    if (_day(date) == today) return DateFormat.Hm().format(date);
    if (date.year == today.year) return DateFormat('d MMM').format(date);
    return DateFormat('d MMM y').format(date);
  }

  static bool isOverdue(DateTime due, {DateTime? now}) =>
      _day(due).isBefore(_day(now ?? DateTime.now()));
}
