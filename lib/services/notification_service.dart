import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter/material.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future init() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  static Future<bool> requestPermissionsWithRationale(BuildContext context) async {
    if (!context.mounted) return false;

    // Önce izin verilmiş mi kontrol edelim
    bool isGranted = false;
    if (Platform.isAndroid) {
      final androidImplementation = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final hasPermission = await androidImplementation?.areNotificationsEnabled();
      if (hasPermission == true) return true;
    }

    if (!context.mounted) return false;

    final agreed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141829),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Bildirim İzni', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'SubsTrack, abonelik yenileme tarihlerinden önce sizi bilgilendirmek için bildirim göndermek istiyor.\n\n'
          'Bildirimler yalnızca abonelik hatırlatmaları ve aylık özet için kullanılacaktır.',
          style: TextStyle(color: Color(0xFFB0B8D1), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hayır', style: TextStyle(color: Color(0xFF8892A4))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('İzin Ver'),
          ),
        ],
      ),
    );

    if (agreed != true) return false;

    if (Platform.isAndroid) {
      final androidImplementation = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final result = await androidImplementation?.requestNotificationsPermission();
      isGranted = result ?? false;
      
      // Request Exact Alarm as well silently if notifications are granted
      if (isGranted) {
        await androidImplementation?.requestExactAlarmsPermission();
      }
    } else if (Platform.isIOS) {
      final iosImplementation = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      final result = await iosImplementation?.requestPermissions(alert: true, badge: true, sound: true);
      isGranted = result ?? false;
    }
    
    return isGranted;
  }

  static Future scheduleReminder({
    required int id,
    required String name,
    required double amount,
    required String currency,
    required DateTime renewalDate,
    int daysBefore = 1,
  }) async {
    await init();
    final notifDate = renewalDate.subtract(Duration(days: daysBefore));
    final now = DateTime.now();
    if (notifDate.isBefore(now)) return;

    final tzDate = tz.TZDateTime(
      tz.local,
      notifDate.year, notifDate.month, notifDate.day, 9, 0,
    );

    try {
      await _plugin.zonedSchedule(
        id,
        'Abonelik Yenileniyor: $name',
        '$daysBefore gun sonra $amount $currency odeme yapilacak.',
        tzDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'substrack_reminders', 'Abonelik Hatirlatmalari',
            channelDescription: 'Yaklasan abonelik odeme bildirimleri',
            importance: Importance.high, priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: Color(0xFF6C5CE7),
          ),
          iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      // Fallback to inexact scheduling if exact alarm permission is denied
      await _plugin.zonedSchedule(
        id,
        'Abonelik Yenileniyor: $name',
        '$daysBefore gun sonra $amount $currency odeme yapilacak.',
        tzDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'substrack_reminders', 'Abonelik Hatirlatmalari',
            channelDescription: 'Yaklasan abonelik odeme bildirimleri',
            importance: Importance.high, priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: Color(0xFF6C5CE7),
          ),
          iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  static Future showTestNotification() async {
    await init();
    await _plugin.show(
      0,
      'Test Bildirimi',
      'SubsTrack bildirimleri duzgun calisiyor!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'substrack_test', 'Test',
          importance: Importance.high, priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFF6C5CE7),
        ),
      ),
    );
  }

  static Future cancel(int id) async => _plugin.cancel(id);
  static Future cancelAll() async => _plugin.cancelAll();

  static Future scheduleMonthlySummary() async {
    await init();
    final now = DateTime.now();
    DateTime nextMonth = DateTime(now.year, now.month + 1, 1, 10, 0); // Next month's 1st day at 10:00 AM

    final tzDate = tz.TZDateTime.from(nextMonth, tz.local);

    try {
      await _plugin.zonedSchedule(
        99999, // Static ID for monthly summary
        'Aylik Ozetiniz Hazir',
        'Bu ayki toplam abonelik harcamalarinizi goruntuleyin.',
        tzDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'substrack_summary', 'Aylik Ozetler',
            channelDescription: 'Aylik abonelik harcama ozetleri',
            importance: Importance.defaultImportance, priority: Priority.defaultPriority,
            icon: '@mipmap/ic_launcher',
            color: Color(0xFF6C5CE7),
          ),
          iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      );
    } catch (e) {
      await _plugin.zonedSchedule(
        99999,
        'Aylik Ozetiniz Hazir',
        'Bu ayki toplam abonelik harcamalarinizi goruntuleyin.',
        tzDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'substrack_summary', 'Aylik Ozetler',
            channelDescription: 'Aylik abonelik harcama ozetleri',
            importance: Importance.defaultImportance, priority: Priority.defaultPriority,
            icon: '@mipmap/ic_launcher',
            color: Color(0xFF6C5CE7),
          ),
          iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      );
    }
  }
}
