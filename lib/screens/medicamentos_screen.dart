import 'package:flutter/material.dart';
import 'package:notifications_programming/database/database_helper.dart';
import 'package:notifications_programming/screens/home_screen.dart';
import 'package:notifications_programming/widgets/custom_bottom_nav.dart';

class MedicamentosScreen extends StatefulWidget {
  const MedicamentosScreen({super.key});

  @override
  State<MedicamentosScreen> createState() => _MedicamentosScreenState();
}

class _MedicamentosScreenState extends State<MedicamentosScreen> {
  // Inicializo con una lista vacía para evitar error de inicialización tardía
  late Future<List<Map<String, dynamic>>> _medicamentosFuture = Future.value([]);

  @override
  void initState() {
    super.initState();
    _loadMedicamentos();
  }

  Future<void> _loadMedicamentos() async {
    final meds = await DatabaseHelper().getMedicamentos();
    setState(() {
      _medicamentosFuture = Future.value(meds);
    });
  }

  Future<void> _eliminarMedicamento(int id) async {
    await DatabaseHelper().deleteMedicamento(id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Medicamento eliminado correctamente.'),
        action: SnackBarAction(
          label: 'Deshacer',
          onPressed: () {
            // Opcional: implementar lógica para restaurar
          },
        ),
      ),
    );
    await _loadMedicamentos();
  }

  Future<void> _editarMedicamento(Map<String, dynamic> medicamento) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(medicamento: medicamento),
      ),
    );
    if (result == true) await _loadMedicamentos();
  }

  Future<void> _agregarMedicamento() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
    if (result == true) await _loadMedicamentos();
  }

  @override
  Widget build(BuildContext context) {
    final primary = const Color.fromARGB(255, 61, 164, 233);
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FA),
      appBar: AppBar(
        title: const Text(
          'Medicamentos',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: primary,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _medicamentosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final medicamentos = snapshot.data;

          if (medicamentos == null || medicamentos.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.medical_services_outlined,
                      size: 130,
                      color: Colors.blueAccent.withOpacity(0.7),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Sin medicamentos registrados',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Agrega tus medicamentos para comenzar a recibir recordatorios y llevar un mejor control.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: medicamentos.length,
            itemBuilder: (context, index) {
              final med = medicamentos[index];
              return Dismissible(
                key: ValueKey(med['id']),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => _eliminarMedicamento(med['id']),
                child: Card(
                  color: Colors.white,
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.medical_services,
                          color: Colors.blueAccent,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                med['nombre'] ?? '',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Dosis: ${med['dosis']} - Cantidad: ${med['cantidad']}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _editarMedicamento(med);
                            } else if (value == 'delete') {
                              _eliminarMedicamento(med['id']);
                            }
                          },
                          itemBuilder: (BuildContext context) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text('Editar'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Eliminar'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _agregarMedicamento,
        child: const Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.teal,
        tooltip: 'Agregar nuevo medicamento',
      ),
      bottomNavigationBar: const CustomBottomNav(selectedIndex: 1),
    );
  }
}
