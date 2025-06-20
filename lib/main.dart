


import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:notifications_programming/screens/home_screen.dart';
import 'package:notifications_programming/screens/hoy_screen.dart';
import 'package:notifications_programming/screens/medicamentos_screen.dart';
import 'package:notifications_programming/services/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 👇 Esto mantiene el splash hasta que completes la carga
  FlutterNativeSplash.preserve(widgetsBinding: WidgetsFlutterBinding.ensureInitialized());

  await requestNotificationPermission();
  await NotificationService().initialize();
  tz.initializeTimeZones();
  await initializeDateFormatting('es', null);

  // 👇 Oculta el splash manualmente
  FlutterNativeSplash.remove();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
     debugShowCheckedModeBanner: false,
     theme: ThemeData(
      primarySwatch: Colors.blue,
      useMaterial3: true,
     ),
      home: const HoyScreen(),

    );
  }
}