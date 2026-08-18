import 'package:intl/intl.dart';

class DateFormatter {
  static String formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('EEE, d MMM yyyy').format(date);
  }

  static String formatEventDate(DateTime? date) => formatDate(date);

  static String formatShortDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('d MMM').format(date);
  }

  static String formatTime(DateTime? date) {
    if (date == null) return '';
    return DateFormat('hh:mm a').format(date);
  }

  static String formatEventTime(DateTime? date) => formatTime(date);

  static String formatDateTime(DateTime? date) {
    if (date == null) return '';
    return DateFormat('d MMM yyyy, hh:mm a').format(date);
  }

  /// Calculates SLA remaining countdown e.g. "18h remaining"
  static String formatSlaRemaining(DateTime? deadline) {
    if (deadline == null) return 'No SLA';
    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (difference.isNegative) {
      return 'SLA Expired';
    }

    if (difference.inDays > 0) {
      return '${difference.inDays}d ${difference.inHours % 24}h remaining';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m remaining';
    } else {
      return '${difference.inMinutes}m remaining';
    }
  }
}
