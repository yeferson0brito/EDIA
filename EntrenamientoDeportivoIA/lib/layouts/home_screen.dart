import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    Center(
      child: Text(
        'Home',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    ),
    Center(
      child: Text(
        'Perfil',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    ),
    Center(
      child: Text(
        'Ajustes',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    ),
  ];

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
    await prefs.remove('rolUser');
    // Navegar al login y eliminar rutas anteriores
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/images/Desplegable_Icon3.png',
            height: 36,
            fit: BoxFit.contain,
          ),
        ),
        title: const Text('EDIA'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Perfil',
            onPressed: () => setState(() => _selectedIndex = 1),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Image.asset("assets/images/Rutina_Outline_Icon.png", height:50),
            activeIcon: Image.asset("assets/images/Rutina_Solid_Icon.png", height:60, ),
          ),
          BottomNavigationBarItem(
            icon: Image.asset("assets/images/Progreso_Outline_Icon.png", height:50),
            activeIcon: Image.asset("assets/images/Progreso_Solid_Icon.png", height:60, ),
          ),
          BottomNavigationBarItem(
           icon: Image.asset("assets/images/Configuraciones_Outline_Icon.png", height:50),
            activeIcon: Image.asset("assets/images/Configuraciones_Solid_Icon.png", height:60, ),
          ),
        ],
      ),
      floatingActionButton: (_selectedIndex == 0)
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'basic',
                  onPressed: () {
                    Navigator.pushNamed(context, '/rolbasic');
                  },
                  icon: const Icon(Icons.person_outline),
                  label: const Text('Usuario Básico'),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.extended(
                  heroTag: 'trainer',
                  onPressed: () {
                    Navigator.pushNamed(context, '/roltrainer');
                  },
                  icon: const Icon(Icons.fitness_center),
                  label: const Text('Entrenador'),
                ),
              ],
            )
          : null,
    );
  }
}