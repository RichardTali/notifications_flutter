import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:notifications_programming/database/database_helper.dart';
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

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

 void _onNotificationTap(NotificationResponse response) async {
  final dbHelper = DatabaseHelper();

  final action = response.actionId;
  final payload = response.payload;

  if (payload == null || !payload.startsWith('medicamento_')) {
    print('❌ Payload inválido: $payload');
    return;
  }

  final recordatorioId = int.tryParse(payload.split('_')[1]);
  if (recordatorioId == null) {
    print('❌ ID no válido en el payload.');
    return;
  }

  print('✅ Acción recibida: $action con ID: $recordatorioId');

  switch (action) {
    case 'TOMAR':
      await dbHelper.registrarToma(recordatorioId, 'tomado');
      break;

    case 'OMITIR':
      await dbHelper.registrarToma(recordatorioId, 'omitido');
      break;

    case 'POSPONER':
      final recordatorio = await dbHelper.getRecordatorioPorId(recordatorioId);
      if (recordatorio == null) return;

      final pos = await dbHelper.contarPosposiciones(recordatorioId);
      if (pos >= 3) return;

      final nuevaHora = DateTime.parse(recordatorio['fecha_hora']).add(const Duration(minutes: 10));

      await scheduleNotification(
        dateTime: nuevaHora,
        id: recordatorio['notificacion_id'] ?? recordatorioId,
        nombreMedicamento: recordatorio['nombre'],
        dosis: recordatorio['dosis'],
        cantidad: recordatorio['cantidad'],
      );

      await dbHelper.registrarToma(recordatorioId, 'pospuesto');
      break;

    default:
      print('⚠️ Acción no reconocida: $action');
  }
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

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

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
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'med_channel',
          'Medicamentos',
          channelDescription: 'Notificaciones para medicamentos',
          importance: Importance.max,
          priority: Priority.high,

          actions: <AndroidNotificationAction>[
            AndroidNotificationAction('TOMAR', 'Tomar'),
            AndroidNotificationAction('OMITIR', 'Omitir'),
            AndroidNotificationAction('POSPONER', 'Posponer 10 min'),
          ],
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
