import 'package:flutter/material.dart';
import 'package:notifications_programming/widgets/custom_bottom_nav.dart';

class MasScreen extends StatelessWidget {


  
  const MasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FA),
      appBar: AppBar(
        title: const Text(
          'Historial',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 61, 164, 233),
        elevation: 0,
      ),
      body: Center(
        child: Text(
          '',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(selectedIndex: 2), // Cambia el índice según la pantalla
    );
  }
}