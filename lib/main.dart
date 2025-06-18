import 'package:flutter/material.dart';
import 'package:notifications_programming/screens/home_screen.dart';
import 'package:notifications_programming/screens/hoy_screen.dart';
import 'package:notifications_programming/screens/medicamentos_screen.dart';
import 'package:notifications_programming/services/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await NotificationService().initialize();

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