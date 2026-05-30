import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import '../models/subscription.dart';

class ExportUtils {
  static Future<void> exportToCSV(List<Subscription> subs) async {
    final StringBuffer csv = StringBuffer();
    // Headers
    csv.writeln('Id,Name,Price(TL),IsUsdBased,UsdAmount,Category,RenewalDay,IsActive');
    
    for (var sub in subs) {
      csv.writeln('${sub.id},"${sub.name}",${sub.priceInTL},${sub.isUsdBased},${sub.usdAmount},"${sub.category}",${sub.renewalDay},${sub.isActive}');
    }

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/substrack_export.csv';
    final file = File(path);
    await file.writeAsString(csv.toString());

    await SharePlus.instance.share(ShareParams(files: [XFile(path, mimeType: 'text/csv')], text: 'SubsTrack Aboneliklerim',));
  }

  static Future<void> exportToCalendar(List<Subscription> subs) async {
    final now = DateTime.now();
    for (var sub in subs) {
      if (!sub.isActive) continue;
      
      int year = now.year;
      int month = now.month;
      
      // If the day already passed this month, schedule for next month
      if (now.day > sub.renewalDay) {
        month++;
        if (month > 12) {
          month = 1;
          year++;
        }
      }

      int validDay = sub.renewalDay;
      final daysInMonth = DateTime(year, month + 1, 0).day;
      if (validDay > daysInMonth) {
        validDay = daysInMonth;
      }

      final date = DateTime(year, month, validDay, 10, 0);

      final Event event = Event(
        title: '${sub.name} Yenileme (₺${sub.priceInTL.toStringAsFixed(0)})',
        description: 'SubsTrack abonelik yenileme hatırlatıcısı.',
        location: 'SubsTrack',
        startDate: date,
        endDate: date.add(const Duration(hours: 1)),
        allDay: true,
        recurrence: Recurrence(
          frequency: Frequency.monthly,
          ocurrences: 12, // Schedule for next 12 months
        ),
      );

      await Add2Calendar.addEvent2Cal(event);
    }
  }

  static Future<void> exportBackupJSON(List<Subscription> subs) async {
    final List<Map<String, dynamic>> jsonList = subs.map((s) => s.toMap()).toList();
    final String jsonString = jsonEncode(jsonList);

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/substrack_backup.json';
    final file = File(path);
    await file.writeAsString(jsonString);

    await SharePlus.instance.share(ShareParams(files: [XFile(path, mimeType: 'application/json')], text: 'SubsTrack Yedek Dosyası',));
  }
}
