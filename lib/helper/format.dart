import 'package:intl/intl.dart';
class format{ 
    static String formatPickDate(String? rawDate) {
      if (rawDate == null || rawDate.isEmpty) return '-';
      try {
        final parsedDate = DateTime.parse(rawDate);
        return DateFormat('dd-MMM-yyyy').format(parsedDate);
      } catch (_) {
        return '-';
      }
    }
}
