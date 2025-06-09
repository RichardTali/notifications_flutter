import 'package:flutter/material.dart';
import 'package:notifications_programming/screens/home_screen.dart';

class MedicamentosScreen extends StatelessWidget {
  const MedicamentosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicamentos'),
      ),
      body: const Center(
        child: Text(
          'Lista de medicamentos registrados',
          style: TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: (){
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
          
      },
      child: const Icon(Icons.add),
        tooltip: 'Agregar nuevo medicamento',
      ),
    );
  }
}