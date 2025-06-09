import 'package:flutter/material.dart';
import 'package:notifications_programming/screens/home_screen.dart';
import 'package:notifications_programming/screens/medicamentos_screen.dart';

class HoyScreen extends StatefulWidget {
  const HoyScreen({super.key});

  @override
  State<HoyScreen> createState() => _HoyScreenState();
}

class _HoyScreenState extends State<HoyScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    Center(child: Text('Contenido de Hoy', style: TextStyle(fontSize: 24))),
    const MedicamentosScreen(),
    Center(child: Text('Otros ajustes', style: TextStyle(fontSize: 24))),
  
  ];

  final List<String> _titles = [
    'Hoy',
    'Medicamentos',
    'Otros',
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.today),
            label: 'Hoy',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medication),
            label: 'Medicamentos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: 'Otros',
          ),
        ],
      ),
    );
  }
}