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
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _medNameController = TextEditingController();
  final TextEditingController _doseController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  DateTime selectedDate = DateTime.now();
  List<DateTime> notificationTimes = [];

  void _updateDateTime(DateTime date, TimeOfDay time) {
    setState(() {
      selectedDate = date;
      final newDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      notificationTimes.add(newDateTime);
    });
  }

  Future<void> _scheduleNotifications() async {
    if (!_formKey.currentState!.validate()) return;

    if (notificationTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor, selecciona al menos una hora."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    int idCounter = 1;
    for (DateTime dateTime in notificationTimes) {
      if (dateTime.isAfter(DateTime.now())) {
        await _notificationService.scheduleNotification(dateTime, idCounter++);
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Notificaciones programadas correctamente."),
        backgroundColor: Colors.green,
      ),
    );

    setState(() {
      notificationTimes.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Medicamento'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(
                controller: _medNameController,
                label: 'Nombre del medicamento',
                hint: 'Ej: Paracetamol',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _doseController,
                label: 'Dosis',
                hint: 'Ej: 500mg',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _quantityController,
                label: 'Cantidad',
                hint: 'Ej: 30',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),

              const Text(
                'Seleccionar Fecha y Hora',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              DateTimeSelector(
                selectedDate: selectedDate,
                selectedTime: TimeOfDay.now(),
                onDateTimeChanged: _updateDateTime,
              ),

              const SizedBox(height: 12),
              Text(
                'Horas seleccionadas:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              ...notificationTimes.map(
                (dt) => ListTile(
                  leading: const Icon(Icons.alarm),
                  title: Text('${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} - ${dt.day}/${dt.month}/${dt.year}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        notificationTimes.remove(dt);
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _scheduleNotifications,
                icon: const Icon(Icons.save),
                label: const Text('Guardar Notificación'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: (value) =>
              value == null || value.isEmpty ? 'Campo obligatorio' : null,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: hint,
          ),
        ),
      ],
    );
  }
}
