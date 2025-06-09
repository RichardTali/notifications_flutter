import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;


class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );
  
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,

      
    );
 
  }

  void _onNotificationTap(NotificationResponse response) {
    
    //you can navigate to any screen when notification clicked
    print("Notification Clicked: ${response.payload}");
  }

  Future<void> showInstantNotification() async{
    const AndroidNotificationDetails androidPlatformChannelSpecifies = AndroidNotificationDetails(
      'instant_channel',
      'Instant Notifications',
      channelDescription: 'Channel for notification',
      importance: Importance.max,
      priority: Priority.high,
    );


    const NotificationDetails platformChannelSpecifies = NotificationDetails(android: androidPlatformChannelSpecifies);

    //you can customize title and description of notification and you can also make it dynamic
    await flutterLocalNotificationsPlugin.show(
      0,
      'Title of Notification',
      "Description of Notification", 
      platformChannelSpecifies,
      payload:'instant',
    );
  }

  Future<void> scheduleNotification(DateTime scheduleDateTime, int id) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifies =
      AndroidNotificationDetails(
    'instant_channel',
    'Instant Notifications',
    channelDescription: 'Channel for notification',
    importance: Importance.max,
    priority: Priority.high,
  );

  const NotificationDetails platformChannelSpecifies =
      NotificationDetails(android: androidPlatformChannelSpecifies);

  await flutterLocalNotificationsPlugin.zonedSchedule(
    id, // <- ID único por notificación
    'Recordatorio de medicamento',
    "Es hora de tomar tu medicamento",
    tz.TZDateTime.from(scheduleDateTime, tz.local),
    platformChannelSpecifies,
    payload: 'scheduled',
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    
    matchDateTimeComponents: DateTimeComponents.dateAndTime,
  );
}



}
