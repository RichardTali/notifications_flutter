import 'package:flutter/material.dart';
import '../screens/hoy_screen.dart';
import '../screens/medicamentos_screen.dart';
import '../screens/mas_screen.dart';

class CustomBottomNav extends StatelessWidget {
  final int selectedIndex;

  const CustomBottomNav({
    Key? key,
    required this.selectedIndex,
  }) : super(key: key);

  void _onItemTapped(BuildContext context, int index) {
    if (index == selectedIndex) return;

    Widget destination;
    if (index == 0) {
      destination = const HoyScreen();
    } else if (index == 1) {
      destination = const MedicamentosScreen();
    } else {
      destination = const MasScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      selectedItemColor: Colors.blueAccent,
      unselectedItemColor: Colors.grey,
      onTap: (index) => _onItemTapped(context, index),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.alarm), label: 'Hoy'),
        BottomNavigationBarItem(
          icon: Icon(Icons.medical_services),
          label: 'Medicamentos',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Historial'),
      ],
    );
  }
}