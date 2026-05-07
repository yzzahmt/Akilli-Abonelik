import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/subscription.dart';
import 'database_service.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  NotificationService._init();

  Future<void> init() async {
    try {
      tz.initializeTimeZones();

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await _plugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) async {},
      );

      // Request notification permissions explicitly for Android 13+
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      // Reschedule all active notifications silently
      await rescheduleAllActiveNotifications();
    } catch (_) {
      // Silently ignore – permissions may not be granted yet
    }
  }

  Future<void> rescheduleAllActiveNotifications() async {
    try {
      final activeSubs = await DBService.instance.getAllSubscriptions();
      await _plugin.cancelAll();
      for (var sub in activeSubs) {
        if (sub.isActive && sub.id != null) {
          await scheduleRenewalNotification(sub);
        }
      }
    } catch (_) {}
  }

  Future<void> scheduleRenewalNotification(Subscription sub) async {
    if (sub.id == null || !sub.isActive) return;

    try {
      final now = DateTime.now();
      final notifyBefore = sub.notifyDaysBefore > 0 ? sub.notifyDaysBefore : 1;

      // Calculate scheduled day (renewalDay - notifyBefore), clamped to valid range
      int scheduleDay = sub.renewalDay - notifyBefore;
      if (scheduleDay < 1) scheduleDay = 1;

      DateTime scheduledDate = DateTime(now.year, now.month, scheduleDay, 10, 0);

      if (scheduledDate.isBefore(now)) {
        int nextMonth = now.month + 1;
        int nextYear = now.year;
        if (nextMonth > 12) {
          nextMonth = 1;
          nextYear++;
        }
        scheduledDate = DateTime(nextYear, nextMonth, scheduleDay, 10, 0);
      }

      final scheduledTZDate = tz.TZDateTime.from(scheduledDate, tz.UTC);

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'renewal_channel',
        'Yenileme Hatırlatıcıları',
        channelDescription: 'Abonelik yenileme tarihlerinden önce gönderilen hatırlatıcılar.',
        importance: Importance.max,
        priority: Priority.high,
      );

      const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails();

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      await _plugin.zonedSchedule(
        id: sub.id!,
        title: '⏰ Yaklaşan Yenileme',
        body: '${sub.name} yakında yenileniyor — ₺${sub.priceInTL.toStringAsFixed(0)} çekilecek',
        scheduledDate: scheduledTZDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (_) {
      // Skip silently – exact alarms may not be permitted on all devices
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await _plugin.cancel(id: id);
    } catch (_) {}
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}
