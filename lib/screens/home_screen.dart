

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notifications_programming/database/database_helper.dart';
import 'package:notifications_programming/services/notification_service.dart';

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

  String? _selectedDose;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  List<TimeOfDay> _horasPorDia = [];

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

      // Cargar fechas y horas de recordatorios existentes
      _fechaInicio = widget.medicamento!['fecha_inicio'] != null
          ? DateTime.parse(widget.medicamento!['fecha_inicio'])
          : null;
      _fechaFin = widget.medicamento!['fecha_fin'] != null
          ? DateTime.parse(widget.medicamento!['fecha_fin'])
          : null;

      _loadHorasDeRecordatorios();
    }
  }

  Future<void> _loadHorasDeRecordatorios() async {
    final dbHelper = DatabaseHelper();
    final recordatorios = await dbHelper.getRecordatorios(widget.medicamento!['id']);
    setState(() {
      _horasPorDia = recordatorios.map((r) {
        final dt = DateTime.parse(r['fecha_hora']);
        return TimeOfDay(hour: dt.hour, minute: dt.minute);
      }).toList();
    });
  }

  Future<void> _selectFechaInicio() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaInicio ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _fechaInicio = picked;
        if (_fechaFin != null && _fechaFin!.isBefore(picked)) {
          _fechaFin = null;
        }
      });
    }
  }

  Future<void> _selectFechaFin() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaFin ?? _fechaInicio ?? DateTime.now(),
      firstDate: _fechaInicio ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _fechaFin = picked;
      });
    }
  }

  Future<void> _selectHora() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        // Evitar duplicados
        if (!_horasPorDia.any((h) => h.hour == picked.hour && h.minute == picked.minute)) {
          _horasPorDia.add(picked);
        }
      });
    }
  }

  Future<void> _scheduleNotifications() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fechaInicio == null || _fechaFin == null || _horasPorDia.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Selecciona el rango de fechas y al menos una hora por día."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final dbHelper = DatabaseHelper();
    int medId;

    final medData = {
      'nombre': _medNameController.text,
      'dosis': _selectedDose ?? '',
      'cantidad': int.tryParse(_quantityController.text) ?? 0,
      'fecha_inicio': _fechaInicio!.toIso8601String(),
      'fecha_fin': _fechaFin!.toIso8601String(),
    };

    if (widget.medicamento != null && widget.medicamento!['id'] != null) {
      medId = widget.medicamento!['id'];
      await dbHelper.updateMedicamento(medId, medData);

      // Eliminar recordatorios viejos para evitar duplicados
      await dbHelper.deleteRecordatoriosByMedicamento(medId);

    } else {
      medId = await dbHelper.insertMedicamento(medData);
    }

    // Generar fechas entre inicio y fin
    List<DateTime> todasLasNotificaciones = [];
    DateTime fechaActual = _fechaInicio!;
    while (!fechaActual.isAfter(_fechaFin!)) {
      for (TimeOfDay hora in _horasPorDia) {
        final dt = DateTime(
          fechaActual.year,
          fechaActual.month,
          fechaActual.day,
          hora.hour,
          hora.minute,
        );
        if (dt.isAfter(DateTime.now())) {
          todasLasNotificaciones.add(dt);
        }
      }
      fechaActual = fechaActual.add(const Duration(days: 1));
    }

    int idCounter = 1;
    for (final dateTime in todasLasNotificaciones) {
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
      _medNameController.clear();
      _quantityController.clear();
      _selectedDose = null;
      _fechaInicio = null;
      _fechaFin = null;
      _horasPorDia.clear();
    });

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color.fromARGB(255, 61, 164, 233);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.medicamento != null ? 'Editar Medicamento' : 'Registrar Medicamento',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
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
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 30),
              const Text('Rango de fechas del tratamiento', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: _selectFechaInicio,
                    icon: const Icon(Icons.date_range),
                    label: Text(_fechaInicio != null
                        ? 'Inicio: ${_fechaInicio!.day}/${_fechaInicio!.month}/${_fechaInicio!.year}'
                        : 'Seleccionar inicio'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _selectFechaFin,
                    icon: const Icon(Icons.date_range_outlined),
                    label: Text(_fechaFin != null
                        ? 'Fin: ${_fechaFin!.day}/${_fechaFin!.month}/${_fechaFin!.year}'
                        : 'Seleccionar fin'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Horarios por día', style: TextStyle(fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: _selectHora,
                icon: const Icon(Icons.access_time),
                label: const Text('Agregar hora'),
              ),
              Column(
                children: _horasPorDia.map((hora) {
                  return ListTile(
                    leading: const Icon(Icons.schedule),
                    title: Text('${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          _horasPorDia.remove(hora);
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _scheduleNotifications,
                icon: const Icon(Icons.save),
                label: Text(widget.medicamento != null ? 'Actualizar' : 'Guardar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 10,
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
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: color),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingresa $label';
        }
        return null;
      },
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
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        prefixIcon: Icon(Icons.medication, color: color),
      ),
      items: items
          .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e),
              ))
          .toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor selecciona $label';
        }
        return null;
      },
    );
  }
}
