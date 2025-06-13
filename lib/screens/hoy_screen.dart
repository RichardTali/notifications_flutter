import 'package:flutter/material.dart';
import 'package:notifications_programming/database/database_helper.dart';
import 'package:notifications_programming/widgets/custom_bottom_nav.dart';

class HoyScreen extends StatefulWidget {
  const HoyScreen({Key? key}) : super(key: key);

  @override
  State<HoyScreen> createState() => _HoyScreenState();
}

class _HoyScreenState extends State<HoyScreen> {
  late Future<List<Map<String, dynamic>>> _recordatoriosDeHoy;

  @override
  void initState() {
    super.initState();
    _loadRecordatorios();
  }

  void _loadRecordatorios() {
    _recordatoriosDeHoy = DatabaseHelper().getRecordatoriosDeHoy();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Si esta pantalla es la actual, recarga los datos
    if (ModalRoute.of(context)?.isCurrent ?? false) {
      setState(() {
        _loadRecordatorios();
      });
    }
  }

 @override
Widget build(BuildContext context) {
  final primaryColor = const Color.fromARGB(255, 61, 164, 233);
  return Scaffold(
    appBar: AppBar(
      title: const Text('Recordatorios de Hoy'),
      backgroundColor: primaryColor,
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper().getRecordatoriosDeHoy(), // <-- ¡Aquí!
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No hay recordatorios para hoy.'));
        }
        final recordatorios = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: recordatorios.length,
          itemBuilder: (context, index) {
            final rec = recordatorios[index];
            final fechaHora = DateTime.parse(rec['fecha_hora']);
            final hora = '${fechaHora.hour.toString().padLeft(2, '0')}:${fechaHora.minute.toString().padLeft(2, '0')}';

            return Card(
              color: primaryColor.withOpacity(0.08),
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
                trailing: Icon(Icons.alarm, color: primaryColor),
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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