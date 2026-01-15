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
    Center(
      child: Text(
        'Hidratación',
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

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Cerrar Sesión"),
          content: const Text("¿Estás seguro de que deseas salir?"),
          actions: [
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("Salir"),
              onPressed: () {
                Navigator.of(context).pop();
                _logout(context);
              },
            ),
          ],
        );
      },
    );
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
              'assets/images/IconDropdown.png',
              height: 36,
              fit: BoxFit.contain,
            ),
          ),
        ),
        title: Text('NEMA',
        style: GoogleFonts.montserrat(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: Color(0xFF134E5E),
            
          ),
        ),
        centerTitle: true,
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
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFF134E5E)),
              title: Text(
                'Cerrar Sesión',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF134E5E),
                ),
              ),
              onTap: _confirmLogout,
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Necesario para más de 3 items
        backgroundColor: Colors.grey[200],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedLabelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        unselectedLabelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
        selectedItemColor: const Color(0xFF134E5E),
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Image.asset("assets/images/IconCardsOutline.png", height:40, errorBuilder: (context, error, stackTrace) => const Icon(Icons.fitness_center),),
            activeIcon: Image.asset("assets/images/IconCardsSolid.png", height:50, errorBuilder: (context, error, stackTrace) => const Icon(Icons.fitness_center),),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Image.asset("assets/images/IconProgressOutline.png", height:40),
            activeIcon: Image.asset("assets/images/IconProgressSolid.png", height:50, ),
            label: 'Progreso'
          ),
          BottomNavigationBarItem(
           icon: Image.asset("assets/images/IconRecordOutline.png", height:40),
            activeIcon: Image.asset("assets/images/IconRecordSolid.png", height:50, ),
            label: 'Historial'
          ),
          BottomNavigationBarItem(
            icon: Image.asset("assets/images/IconWaterOutline.png", height:40),
            activeIcon: Image.asset("assets/images/IconWaterSolid.png", height:50),
            label: 'Hidratación'
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