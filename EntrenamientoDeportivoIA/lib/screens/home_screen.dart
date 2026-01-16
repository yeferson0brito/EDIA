import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

import 'progress_screen.dart';
import 'record_screen.dart';
import 'hydration_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _username = "Usuario"; // Valor por defecto
  late PageController _pageController;

  final List<String> _titles = ['NEMA', 'PROGRESO', 'HISTORIAL', 'HIDRATACIÓN'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _username = prefs.getString('username') ?? "Usuario");
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
    await prefs.remove('rolUser');
    // Navegar al login y eliminar rutas anteriores
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  //CONFIRMACIÓN DE SALIDA
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
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  //TARJETAS
  Widget _buildDashboardCard({
    required double height,
    required String title,
    required IconData icon,
  }) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100], //paleta
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: const Color(0xFF134E5E)),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF134E5E),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.grey[300],
        leading: Container(
          margin: const EdgeInsets.only(left: 10),
          child: GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Image.asset(
                'assets/images/IconDropdown.png',
                height: 30,
                
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        title: Text(
          _titles[_selectedIndex],
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
              decoration: const BoxDecoration(color: Colors.white),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF134E5E),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.transparent,
                      child: Image.asset(
                        'assets/images/Configuraciones_Solid_Icon.png',
                        fit: BoxFit.contain,
                      ),
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
              leading: const Icon(Icons.settings, color: Color(0xFF134E5E)),
              title: Text(
                'Configuraciones',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF134E5E),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline, color: Color(0xFF134E5E)),
              title: Text(
                'Ayuda',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF134E5E),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
              },
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

      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          setState(() => _selectedIndex = index);
        },
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Tarjeta 1: Ancho completo
                _buildDashboardCard(
                  height: 150,
                  title: 'CONSEJO DIARIO',
                  icon: Icons.today,
                ),
                const SizedBox(height: 16),
                // Fila de 2 tarjetas (50% cada una)
                Row(
                  children: [
                    Expanded(
                      child: _buildDashboardCard(
                        height: 150,
                        title: 'Calorías',
                        icon: Icons.local_fire_department,
                      ),
                    ),
                    const SizedBox(width: 16), // Espacio entre ellas
                    Expanded(
                      child: _buildDashboardCard(
                        height: 150,
                        title: 'Pasos',
                        icon: Icons.directions_walk,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Tarjeta 4: Ancho completo (Nueva)
                _buildDashboardCard(
                  height: 120,
                  title: 'Próximo Entreno',
                  icon: Icons.fitness_center,
                ),
              ],
            ),
          ),
          const ProgressScreen(),
          const RecordScreen(),
          const HydrationScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Necesario para más de 3 items
        backgroundColor: Colors.grey[300],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedLabelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        unselectedLabelStyle: GoogleFonts.montserrat(
          fontWeight: FontWeight.w500,
        ),
        selectedItemColor: const Color(0xFF134E5E),
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Image.asset(
              "assets/images/IconCardsOutline.png",
              height: 40,
              errorBuilder:
                  (context, error, stackTrace) =>
                      const Icon(Icons.fitness_center),
            ),
            activeIcon: Image.asset(
              "assets/images/IconCardsSolid.png",
              height: 50,
              errorBuilder:
                  (context, error, stackTrace) =>
                      const Icon(Icons.fitness_center),
            ),
            label: 'Tablero',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              "assets/images/IconProgressOutline.png",
              height: 40,
            ),
            activeIcon: Image.asset(
              "assets/images/IconProgressSolid.png",
              height: 50,
            ),
            label: 'Progreso',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              "assets/images/IconRecordOutline.png",
              height: 40,
            ),
            activeIcon: Image.asset(
              "assets/images/IconRecordSolid.png",
              height: 50,
            ),
            label: 'Historial',
          ),
          BottomNavigationBarItem(
            icon: Image.asset("assets/images/IconWaterOutline.png", height: 40),
            activeIcon: Image.asset(
              "assets/images/IconWaterSolid.png",
              height: 50,
            ),
            label: 'Hidratación',
          ),
        ],
      ),
      floatingActionButton:
          (_selectedIndex == 0)
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
