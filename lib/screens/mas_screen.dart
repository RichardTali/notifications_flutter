

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
    final result = await db.rawQuery('''
      SELECT rt.id, rt.fecha, rt.estado, r.id as recordatorio_id,
             m.nombre AS nombre_medicamento, m.dosis, m.cantidad
      FROM registro_tomas rt
      JOIN (
        SELECT recordatorio_id, MAX(fecha) as ultima_fecha
        FROM registro_tomas
        GROUP BY recordatorio_id
      ) ultimos 
        ON rt.recordatorio_id = ultimos.recordatorio_id 
       AND rt.fecha = ultimos.ultima_fecha
      JOIN recordatorios r ON rt.recordatorio_id = r.id
      JOIN medicamentos m ON r.medicamento_id = m.id
      ORDER BY rt.fecha DESC
    ''');
    if (_filtroEstado != 'todos') {
      return result.where((item) => item['estado'] == _filtroEstado).toList();
    }
    return result;
  }

  IconData iconoPorEstado(String e) {
    switch (e) {
      case 'tomado': return Icons.check_circle;
      case 'omitido': return Icons.cancel;
      case 'pospuesto': return Icons.schedule;
      default: return Icons.help_outline;
    }
  }

  Color colorPorEstado(String e) {
    switch (e) {
      case 'tomado': return Colors.green;
      case 'omitido': return Colors.red;
      case 'pospuesto': return Colors.orange;
      default: return Colors.grey;
    }
  }

  String formatearFecha(String iso) {
    final f = DateTime.parse(iso);
    return DateFormat('d MMMM y', 'es').format(f);
  }
  String formatearHora(String iso) {
    final f = DateTime.parse(iso);
    return DateFormat.Hm().format(f);
  }

  @override
  Widget build(BuildContext context) {
    final primary = const Color.fromARGB(255, 61, 164, 233);


    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FA),
      appBar: AppBar(
        title: const Text('Historial', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true, backgroundColor: primary, elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onSelected: (v) => setState(() => _filtroEstado = v),
            itemBuilder: (_) => const [
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
        builder: (c, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data ?? [];
          if (data.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_edu_rounded, size: 100, color: primary.withOpacity(0.6)),
                  const SizedBox(height: 16),
                  const Text('Aún no hay historial', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text(
                    'Aquí verás el último estado de cada recordatorio.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Cálculo de resumen
          int t = data.where((e) => e['estado']=='tomado').length;
          int o = data.where((e) => e['estado']=='omitido').length;
          int p = data.where((e) => e['estado']=='pospuesto').length;

          // Agrupar por fecha (día)
          Map<String, List<Map<String, dynamic>>> grupos = {};
          for (var item in data) {
            final dia = formatearFecha(item['fecha']);
            grupos.putIfAbsent(dia, () => []).add(item);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Resumen
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildBadge(Icons.check_circle, t, Colors.green),
                  _buildBadge(Icons.cancel, o, Colors.red),
                  _buildBadge(Icons.schedule, p, Colors.orange),
                ],
              ),
              const SizedBox(height: 16),

              // Listado por fecha
              for (var dia in grupos.keys) ...[
                Text('📅 $dia', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                for (var item in grupos[dia]!) Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: Icon(iconoPorEstado(item['estado']), color: colorPorEstado(item['estado']), size: 32),
                    title: Text(item['nombre_medicamento'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      '${item['dosis']} • Cant: ${item['cantidad']}  – '
                      '${item['estado'][0].toUpperCase()}${item['estado'].substring(1)} '
                      'a las ${formatearHora(item['fecha'])}',
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],
          );
        },
      ),
      bottomNavigationBar: const CustomBottomNav(selectedIndex: 2),
    );
  }

  Widget _buildBadge(IconData icon, int count, Color color) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 4),
        Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
