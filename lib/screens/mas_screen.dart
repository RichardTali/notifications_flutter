import 'package:flutter/material.dart';
import 'package:notifications_programming/widgets/custom_bottom_nav.dart';

class MasScreen extends StatelessWidget {


  
  const MasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Más'),
        backgroundColor: const Color.fromARGB(255, 61, 164, 233),
      ),
      body: Center(
        child: Text(
          'Más Screen',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(selectedIndex: 2), // Cambia el índice según la pantalla
    );
  }
}