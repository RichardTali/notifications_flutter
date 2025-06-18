import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notifications_programming/database/database_helper.dart';
import 'package:notifications_programming/widgets/custom_bottom_nav.dart';

class MasScreen extends StatefulWidget {
  const MasScreen({super.key});

  @override
  State<MasScreen> createState() => _MasScreenState();
}

class _MasScreenState extends State<MasScreen> {
  String _filtroEstado = 'todos';

  Future<List<Map<String, dynamic>>> obtenerHistorial() async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT rt.id, rt.fecha, rt.estado,
             m.nombre AS nombre_medicamento
      FROM registro_tomas rt
      JOIN recordatorios r ON rt.recordatorio_id = r.id
      JOIN medicamentos m ON r.medicamento_id = m.id
      ORDER BY rt.fecha DESC
    ''');

    if (_filtroEstado == 'todos') return result;
    return result.where((item) => item['estado'] == _filtroEstado).toList();
  }

  IconData iconoPorEstado(String estado) {
    switch (estado) {
      case 'tomado':
        return Icons.check_circle;
      case 'omitido':
        return Icons.cancel;
      case 'pospuesto':
        return Icons.access_time;
      default:
        return Icons.help_outline;
    }
  }

  Color colorPorEstado(String estado) {
    switch (estado) {
      case 'tomado':
        return Colors.green;
      case 'omitido':
        return Colors.red;
      case 'pospuesto':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String formatearFechaHora(String fechaIso) {
    final fecha = DateTime.parse(fechaIso);
    final fechaFormat = DateFormat.yMMMMd('es').format(fecha);
    final horaFormat = DateFormat.Hm().format(fecha);
    return '$fechaFormat a las $horaFormat';
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color.fromARGB(255, 61, 164, 233);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FA),
      appBar: AppBar(
        title: const Text(
          'Historial',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onSelected: (value) {
              setState(() {
                _filtroEstado = value;
              });
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'todos', child: Text('Mostrar todos')),
              PopupMenuItem(value: 'tomado', child: Text('Solo tomados')),
              PopupMenuItem(value: 'omitido', child: Text('Solo omitidos')),
              PopupMenuItem(value: 'pospuesto', child: Text('Solo pospuestos')),
            ],
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: obtenerHistorial(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar historial: ${snapshot.error}'));
          }

          final historial = snapshot.data ?? [];

          if (historial.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history_edu_rounded, size: 100, color: primaryColor.withOpacity(0.6)),
                    const SizedBox(height: 24),
                    const Text(
                      'Aún no hay historial',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Aquí se mostrarán los medicamentos que tomaste, omitiste o pospusiste.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: historial.length,
            itemBuilder: (context, index) {
              final item = historial[index];
              final estado = item['estado'] ?? '';
              final fechaTexto = formatearFechaHora(item['fecha']);

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Icon(
                    iconoPorEstado(estado),
                    color: colorPorEstado(estado),
                    size: 30,
                  ),
                  title: Text(
                    item['nombre_medicamento'] ?? 'Medicamento',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${estado[0].toUpperCase()}${estado.substring(1)} • $fechaTexto',
                    style: const TextStyle(color: Colors.black87),
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: const CustomBottomNav(selectedIndex: 2),
    );
  }
}
