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

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    // Puedes navegar a una pantalla específica cuando se pulse la notificación
    print("Notification Clicked: ${response.payload}");
  }

  Future<void> showInstantNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'instant_channel',
      'Instant Notifications',
      channelDescription: 'Channel for notification',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Title of Notification',
      "Description of Notification",
      platformChannelSpecifics,
      payload: 'instant',
    );
  }

  Future<void> scheduleNotification({
  required DateTime dateTime,
  required int id,
  required String nombreMedicamento,
  required int cantidad,
  required String dosis,
}) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'med_channel',
    'Medicamentos',
    channelDescription: 'Notificaciones para medicamentos',
    importance: Importance.max,
    priority: Priority.high,
  );

  const NotificationDetails platformDetails = NotificationDetails(
    android: androidDetails,
  );

  final tz.TZDateTime scheduledDate = tz.TZDateTime.from(dateTime, tz.local);

  final hora =
      '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

  final mensaje = 
      'Es hora de tomar su medicina:\n'
      '$nombreMedicamento,\n'
      '$dosis:\n'
      '$cantidad.0,\n'
      '$hora';

  await flutterLocalNotificationsPlugin.zonedSchedule(
    id,
    'Hora de tomar tu medicamento',
    mensaje,
    scheduledDate,
    platformDetails,
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    payload: 'medicamento_$id',
  );
}







}
