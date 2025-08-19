/// Utilidad para formatear fechas y tiempo relativo
class TimeFormatter {
  /// Formatea una fecha como tiempo relativo (ej: "hace 2 horas")
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      final days = difference.inDays;
      if (days == 1) {
        return 'hace 1 día';
      } else if (days < 30) {
        return 'hace $days días';
      } else if (days < 365) {
        final months = (days / 30).floor();
        return months == 1 ? 'hace 1 mes' : 'hace $months meses';
      } else {
        final years = (days / 365).floor();
        return years == 1 ? 'hace 1 año' : 'hace $years años';
      }
    } else if (difference.inHours > 0) {
      final hours = difference.inHours;
      return hours == 1 ? 'hace 1 hora' : 'hace $hours horas';
    } else if (difference.inMinutes > 0) {
      final minutes = difference.inMinutes;
      return minutes == 1 ? 'hace 1 minuto' : 'hace $minutes minutos';
    } else {
      return 'ahora mismo';
    }
  }

  /// Formatea una fecha como fecha absoluta (ej: "12 Ago 2025")
  static String formatAbsoluteDate(DateTime dateTime) {
    final months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];

    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
  }

  /// Formatea una fecha como fecha y hora (ej: "12 Ago 2025, 14:30")
  static String formatDateTime(DateTime dateTime) {
    final date = formatAbsoluteDate(dateTime);
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$date, $hour:$minute';
  }
}
