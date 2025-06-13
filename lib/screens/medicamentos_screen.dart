import 'package:flutter/material.dart';
import 'package:notifications_programming/database/database_helper.dart';
import 'package:notifications_programming/screens/home_screen.dart';

class MedicamentosScreen extends StatefulWidget {
  const MedicamentosScreen({super.key});

  @override
  State<MedicamentosScreen> createState() => _MedicamentosScreenState();
}

class _MedicamentosScreenState extends State<MedicamentosScreen> {
  late Future<List<Map<String, dynamic>>> _medicamentosFuture;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadMedicamentos();
  }

  void _loadMedicamentos() {
    _medicamentosFuture = DatabaseHelper().getMedicamentos();
  }

  Future<void> _eliminarMedicamento(int id) async {
    await DatabaseHelper().deleteMedicamento(id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Medicamento eliminado correctamente.')),
    );
    setState(() {
      _loadMedicamentos();
    });
  }

  Future<void> _editarMedicamento(Map<String, dynamic> medicamento) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(medicamento: medicamento),
      ),
    );

    if (result == true) {
      setState(() {
        _loadMedicamentos();
      });
    }
  }

  Future<void> _agregarMedicamento() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      ),
    );

    if (result == true) {
      setState(() {
        _loadMedicamentos();
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // Aquí puedes navegar a otras pantallas según el índice
      // Por ahora solo mantiene el índice seleccionado
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FA),
      appBar: AppBar(
        title: const Text(
          'Medicamentos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
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
            return const Center(
              child: Text(
                'No hay medicamentos registrados',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: medicamentos.length,
            itemBuilder: (context, index) {
              final med = medicamentos[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  leading: const Icon(Icons.medical_services,
                      color: Colors.blueAccent),
                  title: Text(
                    med['nombre'] ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  subtitle: Text(
                    'Dosis: ${med['dosis'] ?? ''}\nCantidad: ${med['cantidad'] ?? ''}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editarMedicamento(med);
                      } else if (value == 'delete') {
                        _eliminarMedicamento(med['id']);
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Text('Editar'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Text('Eliminar'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _agregarMedicamento,
        child: const Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
        tooltip: 'Agregar nuevo medicamento',
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services),
            label: 'Medicamentos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.alarm),
            label: 'Recordatorios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Configuración',
          ),
        ],
      ),
    );
  }
}
