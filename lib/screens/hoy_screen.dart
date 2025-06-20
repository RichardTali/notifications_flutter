

import 'package:flutter/material.dart';
import 'package:notifications_programming/database/database_helper.dart';
import 'package:notifications_programming/screens/medicamentos_screen.dart';
import 'package:notifications_programming/services/notification_service.dart';
import 'package:notifications_programming/widgets/custom_bottom_nav.dart';
import 'package:notifications_programming/screens/home_screen.dart';

class HoyScreen extends StatefulWidget {
  const HoyScreen({Key? key}) : super(key: key);

  @override
  State<HoyScreen> createState() => _HoyScreenState();
}

class _HoyScreenState extends State<HoyScreen> with WidgetsBindingObserver {
  late Future<List<Map<String, dynamic>>> _recordatoriosDeHoy;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationService().onActionReceived.addListener(_onNotificationAction);
    _loadRecordatorios();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NotificationService().onActionReceived.removeListener(
      _onNotificationAction,
    );
    super.dispose();
  }

  @override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    _loadRecordatorios().then((_) {
      setState(() {});
    });
  }
}


  void _onNotificationAction() async {
  print('[HOYSCREEN] actionReceived, recargando...');
  await _loadRecordatorios();
  setState(() {});
}




  Future<void> _loadRecordatorios() async {
  _recordatoriosDeHoy = DatabaseHelper().getRecordatoriosDeHoy();
}



  void _registrarAccion(int recordatorioId, String estado) async {
    await DatabaseHelper().registrarToma(recordatorioId, estado);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Acción "$estado" registrada')));
    setState(() {
      _loadRecordatorios();
    });
  }

  void _posponer10Min(Map<String, dynamic> rec) async {
    final dbHelper = DatabaseHelper();

    int posposiciones = await dbHelper.contarPosposiciones(rec['id']);

    if (posposiciones >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Has alcanzado el máximo de posposiciones (3).'),
        ),
      );
      return;
    }

    final nuevaHora = DateTime.parse(
      rec['fecha_hora'],
    ).add(const Duration(minutes: 2));

    await NotificationService().scheduleNotification(
      dateTime: nuevaHora,
      id: rec['notificacion_id'],
      nombreMedicamento: rec['nombre'],
      dosis: rec['dosis'],
      cantidad: rec['cantidad'],
    );

    await dbHelper.registrarToma(rec['id'], 'pospuesto');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notificación pospuesta 10 minutos.')),
    );

    setState(() {
      _loadRecordatorios();
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color.fromARGB(255, 61, 164, 233);
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FA),
      appBar: AppBar(
        title: const Text(
          'Recordatorios de Hoy',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _recordatoriosDeHoy,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            // Aquí la pantalla amigable para cuando está vacío
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Puedes poner una imagen o icono bonito aquí
                    Icon(
                      Icons.medication,
                      size: 130,
                      color: primaryColor.withOpacity(0.6),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No hay recordatorios para hoy',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Parece que no tienes recordatorios activos. Agrega tus medicamentos para recibir alertas.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HomeScreen(),
                          ),
                        ).then((_) {
                          setState(() {
                            _loadRecordatorios();
                          });
                        });
                      },
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text(
                        'Agregar Medicamento',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        backgroundColor: Colors.teal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final recordatorios = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: recordatorios.length,
            itemBuilder: (context, index) {
              final rec = recordatorios[index];
              final fechaHora = DateTime.parse(rec['fecha_hora']);
              final hora =
                  '${fechaHora.hour.toString().padLeft(2, '0')}:${fechaHora.minute.toString().padLeft(2, '0')}';

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: primaryColor,
                    child: const Icon(Icons.medication, color: Colors.white),
                  ),
                  title: Text(
                    rec['nombre'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dosis: ${rec['dosis']}'),
                      Text('Cantidad: ${rec['cantidad']}'),
                      Text('Hora: $hora'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () => _registrarAccion(rec['id'], 'tomado'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () => _registrarAccion(rec['id'], 'omitido'),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.access_time,
                          color: Colors.orange,
                        ),
                        onPressed: () => _posponer10Min(rec),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: const CustomBottomNav(selectedIndex: 0),
    );
  }
}
