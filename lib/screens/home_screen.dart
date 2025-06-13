import 'package:flutter/material.dart';
import 'package:notifications_programming/database/database_helper.dart';
import 'package:notifications_programming/services/notification_service.dart';
import 'package:notifications_programming/widgets/date_time_selector.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic>? medicamento;

  const HomeScreen({Key? key, this.medicamento}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NotificationService _notificationService = NotificationService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _medNameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  DateTime selectedDate = DateTime.now();
  List<DateTime> notificationTimes = [];
  String? _selectedDose;

  final List<String> _doseOptions = [
    'Cápsula',
    'Tableta',
    'Cucharada(s)',
    'Cucharaditas',
    'Gotas',
    'Gramo',
    'Inyección(es)',
    'Miligramos (mg)',
    'Mililitros (ml)',
    'Pastilla(s)',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.medicamento != null) {
      _medNameController.text = widget.medicamento!['nombre'] ?? '';
      _selectedDose = widget.medicamento!['dosis'];
      _quantityController.text = (widget.medicamento!['cantidad'] ?? '').toString();
    }
  }

  void _updateDateTime(DateTime date, TimeOfDay time) {
    setState(() {
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

    final dbHelper = DatabaseHelper();
    int medId;

    if (widget.medicamento != null && widget.medicamento!['id'] != null) {
      medId = widget.medicamento!['id'];
      await dbHelper.updateMedicamento(medId, {
        'nombre': _medNameController.text,
        'dosis': _selectedDose ?? '',
        'cantidad': int.tryParse(_quantityController.text) ?? 0,
      });
    } else {
      medId = await dbHelper.insertMedicamento({
        'nombre': _medNameController.text,
        'dosis': _selectedDose ?? '',
        'cantidad': int.tryParse(_quantityController.text) ?? 0,
      });
    }

    int idCounter = 1;
    for (final dateTime in notificationTimes) {
      if (dateTime.isAfter(DateTime.now())) {
        await _notificationService.scheduleNotification(
          dateTime: dateTime,
          id: idCounter,
          nombreMedicamento: _medNameController.text,
          cantidad: int.tryParse(_quantityController.text) ?? 0,
          dosis: _selectedDose ?? '',
        );

        await dbHelper.insertRecordatorio({
          'medicamento_id': medId,
          'fecha_hora': dateTime.toIso8601String(),
          'notificacion_id': idCounter,
        });

        idCounter++;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.medicamento != null
              ? "Medicamento actualizado correctamente."
              : "Medicamento y notificaciones guardadas correctamente.",
        ),
        backgroundColor: Colors.green,
      ),
    );

    setState(() {
      notificationTimes.clear();
      _medNameController.clear();
      _quantityController.clear();
      _selectedDose = null;
    });

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.teal;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.medicamento != null ? 'Editar Medicamento' : 'Registrar Medicamento'),
        backgroundColor: primaryColor,
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
                icon: Icons.medication,
                color: primaryColor,
              ),
              const SizedBox(height: 20),
              _buildDropdownField(
                label: 'Dosis',
                value: _selectedDose,
                items: _doseOptions,
                onChanged: (value) => setState(() => _selectedDose = value),
                color: primaryColor,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _quantityController,
                label: 'Cantidad',
                hint: 'Ej: 30',
                icon: Icons.format_list_numbered,
                keyboardType: TextInputType.number,
                color: primaryColor,
              ),
              const SizedBox(height: 30),
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
              const SizedBox(height: 20),
              const Text(
                'Horas seleccionadas:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (notificationTimes.isEmpty)
                const Text('No se ha seleccionado ninguna hora.'),
              ...notificationTimes.map(
                (dt) => Card(
                  color: primaryColor.withOpacity(0.1),
                  child: ListTile(
                    leading: const Icon(Icons.alarm),
                    title: Text(
                      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} - ${dt.day}/${dt.month}/${dt.year}',
                    ),
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
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _scheduleNotifications,
                icon: const Icon(Icons.save),
                label: Text(widget.medicamento != null ? 'Actualizar' : 'Guardar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 5,
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
    required IconData icon,
    required Color color,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: (value) => (value == null || value.isEmpty) ? 'Campo obligatorio' : null,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: color),
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: color),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    required Color color,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items
          .map((dose) => DropdownMenuItem<String>(
                value: dose,
                child: Text(dose),
              ))
          .toList(),
      onChanged: onChanged,
      validator: (value) => (value == null || value.isEmpty) ? 'Selecciona una dosis' : null,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.medical_services, color: color),
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: color),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
