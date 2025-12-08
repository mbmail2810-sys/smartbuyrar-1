import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings =
        InitializationSettings(android: androidInit);
    await _flutterLocalNotificationsPlugin.initialize(settings);
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'smartbuy_channel',
          'SmartBuy Reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exact,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'smartbuy_budget_channel',
          'SmartBuy Budget Alerts',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  Future<void> showBudgetWarningNotification(String listTitle, double percentUsed) async {
    await showInstantNotification(
      id: listTitle.hashCode,
      title: 'Budget Warning',
      body: 'You\'ve used ${percentUsed.toStringAsFixed(0)}% of your budget for "$listTitle"',
    );
  }

  Future<void> showBudgetExceededNotification(String listTitle, double overspent) async {
    await showInstantNotification(
      id: listTitle.hashCode + 1,
      title: 'Budget Exceeded!',
      body: 'You\'ve exceeded your budget for "$listTitle" by ₹${overspent.toStringAsFixed(0)}',
    );
  }
}
