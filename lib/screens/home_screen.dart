import 'package:flutter/material.dart';
import 'package:notifications_programming/services/notification_service.dart';
import 'package:notifications_programming/widgets/date_time_selector.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NotificationService _notificationService = NotificationService();
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  Future<void> _sheduleNotification() async {
    final DateTime scheduledDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    //check if selected time is in the past
    if (scheduledDateTime.isBefore(DateTime.now())) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a future date and time'),
          backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    await _notificationService.scheduleNotification(scheduledDateTime);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Notification scheduled for ${scheduledDateTime.toString()}",
        ),
        backgroundColor: Colors.redAccent,
        ),
      );
    }



  }void _updateDateTime(DateTime date,TimeOfDay time) {
    setState(() {
      selectedDate = date;
      selectedTime = time;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:AppBar(
        title: Text('Notification Example'),
      ),
      body:Padding(padding: EdgeInsets.all(16),
      child:Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children:[
          ElevatedButton(onPressed: _notificationService.showInstantNotification,
          style:ElevatedButton.styleFrom(
            backgroundColor:Colors.indigo,
            foregroundColor: Colors.white,
            padding:EdgeInsets.symmetric(vertical: 12),
          ),
          child: Text('Send Instant Notification'),
          ),
          SizedBox(height: 24),
          Text("Schedule Notification",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          ),
          SizedBox(height: 16),
          DateTimeSelector(selectedDate: selectedDate, selectedTime: selectedTime,
          onDateTimeChanged: _updateDateTime,
          ),
          SizedBox(height: 16),
          ElevatedButton(onPressed: _sheduleNotification,
          style:ElevatedButton.styleFrom(
            backgroundColor:Colors.green,
            foregroundColor: Colors.white,
            padding:EdgeInsets.symmetric(vertical: 12),
          ),
          child: Text('shedule Notification'),
          ),
        ]
      ),
      ),
    );
  }
}
