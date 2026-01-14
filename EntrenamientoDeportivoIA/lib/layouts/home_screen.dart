import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _username = "Usuario"; // Valor por defecto

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _username = prefs.getString('username') ?? "Usuario");
  }

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
      key: _scaffoldKey,
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => _scaffoldKey.currentState?.openDrawer(),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              'assets/images/Desplegable_Icon3.png',
              height: 36,
              fit: BoxFit.contain,
            ),
          ),
        ),
        title: const Text('EDIA'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF134E5E), width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.transparent,
                      child: Image.asset('assets/images/Configuraciones_Solid_Icon.png', fit: BoxFit.contain),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      _username,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF134E5E),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Aquí puedes agregar más opciones de menú (ListTile)
          ],
        ),
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
            icon: Image.asset("assets/images/Rutina_Outline_Icon.png", height:50, errorBuilder: (context, error, stackTrace) => const Icon(Icons.fitness_center),),
            activeIcon: Image.asset("assets/images/Rutina_Solid_Icon.png", height:60, errorBuilder: (context, error, stackTrace) => const Icon(Icons.fitness_center),),
            label: 'Rutina'
          ),
          BottomNavigationBarItem(
            icon: Image.asset("assets/images/Progreso_Outline_Icon.png", height:50),
            activeIcon: Image.asset("assets/images/Progreso_Solid_Icon.png", height:60, ),
            label: 'Progreso'
          ),
          BottomNavigationBarItem(
           icon: Image.asset("assets/images/Configuraciones_Outline_Icon.png", height:50),
            activeIcon: Image.asset("assets/images/Configuraciones_Solid_Icon.png", height:60, ),
            label: 'Ajustes'
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