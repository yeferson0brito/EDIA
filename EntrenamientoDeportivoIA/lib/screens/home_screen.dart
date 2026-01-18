import 'package:flutter/material.dart';
import 'dart:math' as math;
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
    // Si prefs.getString devuelve null (porque saltamos login), usamos "Admin (Dev)"
    //setState(() => _username = prefs.getString('username') ?? "Usuario");
    setState(() => _username = prefs.getString('username') ?? "Admin (Dev)");
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

  //TARJETAS}
  Widget _buildDailyTipCard() {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Mitad Izquierda: Textos
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'CONSEJO DIARIO',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF134E5E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Texto de base que en el futuro sera comletado de manera automatica por IA',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          // Mitad Derecha: Imagen con efecto desvanecido
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    child: Image.asset(
                      'assets/images/CardEntrenaInteligente.png', // Imagen ilustrativa
                      fit: BoxFit.cover,
                      alignment: Alignment.centerRight,
                    ),
                  ),
                ),
                // Efecto de desvanecido hacia la izquierda (fondo blanco)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Colors.white, Colors.white.withOpacity(0.0)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TARJETA DE PASOS (Diseño Circular)
  Widget _buildStepsCard() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white,
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
          Text(
            'Pasos',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF134E5E),
            ),
          ),
          const SizedBox(height: 10),
          Stack(
            alignment: Alignment.center,
            children: [
              // Círculo de progreso
              SizedBox(
                height: 60,
                width: 60,
                child: CircularProgressIndicator(
                  value: 5200 / 8000, // Ejemplo estático: 65% completado
                  strokeWidth: 6,
                  backgroundColor: Colors.grey[200],
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFF134E5E)),
                ),
              ),
              // Contador en el medio
              Text(
                '5200',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF134E5E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Objetivo: 8000',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // TARJETA DE HIDRATACIÓN (Reemplaza Calorías)
  Widget _buildHydrationCard() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Icono de campana en la parte superior
          const Positioned(
            top: 15,
            left: 15,
            child: Icon(Icons.notifications_none, size: 20, color: Colors.grey),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 5),
                Text(
                  '48%',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF134E5E),
                  ),
                ),
                Text(
                  '1250ml / 3200ml',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                // Barra de progreso en arco y botón
                SizedBox(
                  height: 55,
                  width: 100,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      CustomPaint(
                        size: const Size(80, 40),
                        painter: _ArcPainter(),
                      ),
                      Positioned(
                        bottom: 0,
                        child: Container(
                          height: 35,
                          width: 35,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TARJETA DE INTENSIDAD DEL DÍA (Reemplaza Próximo Entreno)
  Widget _buildIntensityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt, color: Color(0xFF134E5E)),
              const SizedBox(width: 10),
              Text(
                'Intensidad del día',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF134E5E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          // Lista de ejercicios de ejemplo (Modelo Base)
          _buildExerciseItem(Icons.directions_run, 'Elíptica', '30 min'),
          const SizedBox(height: 10),
          _buildExerciseItem(Icons.pool, 'Natación', '30 min'),
        ],
      ),
    );
  }

  Widget _buildExerciseItem(IconData icon, String name, String duration) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF134E5E)),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        Text(
          duration,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // TARJETA DE SUEÑO (Tips y Trucos)
  Widget _buildSleepCard() {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: AssetImage('assets/images/ImageBoardSleep.png'),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
          ),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            // SECCIÓN 1: INFORMACIÓN (FLEX 3)
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Consejos para dormir',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '¿Problemas para dormir? echa un vistazo',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF134E5E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                      minimumSize: const Size(0, 35),
                    ),
                    child: Text(
                      'Conoce más',
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            // SECCIÓN 2: INDICADOR DE CALIDAD DE SUEÑO (FLEX 1)
            Expanded(
              flex: 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // BARRA DE GRADIENTE
                  Container(
                    width: 12,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white24),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.0, 0.75, 1.0], // El azul domina hasta el 65% antes de volverse naranja
                        colors: [
                          Color(0xFF283593), // Azul Índigo (Más tranquilo y profundo)
                          Color(0xFFFFB74D), // Naranja suave (Pastel)
                          Color.fromARGB(255, 215, 89, 89), // Rojo suave (Pastel)
                        ],
                      ),
                    ),
                  ),
                  // FLECHA INDICADORA
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start, // Apunta arriba (Azul)
                    children: const [
                       SizedBox(height: 10), // Ajuste para alinear con la zona azul
                       Icon(Icons.arrow_left, color: Colors.white, size: 24),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
              leading: const Icon(Icons.person, color: Color(0xFF134E5E)),
              title: Text(
                'Perfil',
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
              leading: const Icon(Icons.flag, color: Color(0xFF134E5E)),
              title: Text(
                'Metas',
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
              leading: const Icon(Icons.person_outline, color: Color(0xFF134E5E)),
              title: Text(
                'Usuario Básico',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF134E5E),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/rolbasic');
              },
            ),
            ListTile(
              leading: const Icon(Icons.fitness_center, color: Color(0xFF134E5E)),
              title: Text(
                'Entrenador',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF134E5E),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/roltrainer');
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
                _buildDailyTipCard(),
                const SizedBox(height: 16),
                // Fila de 2 tarjetas (50% cada una)
                Row(
                  children: [
                    Expanded(
                      child: _buildHydrationCard(),
                    ),
                    const SizedBox(width: 16), // Espacio entre ellas
                    Expanded(
                      child: _buildStepsCard(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Tarjeta 4: Intensidad del día (Reemplaza Próximo Entreno)
                _buildIntensityCard(),
                const SizedBox(height: 16),
                // Tarjeta 5: Sueño / Tips
                _buildSleepCard(),
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
        backgroundColor: Colors.grey[200],
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
              height: 30,
              errorBuilder:
                  (context, error, stackTrace) =>
                      const Icon(Icons.fitness_center),
            ),
            activeIcon: Image.asset(
              "assets/images/IconCardsSolid.png",
              height: 35,
              errorBuilder:
                  (context, error, stackTrace) =>
                      const Icon(Icons.fitness_center),
            ),
            label: 'Tablero',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              "assets/images/IconProgressOutline.png",
              height: 30,
            ),
            activeIcon: Image.asset(
              "assets/images/IconProgressSolid.png",
              height: 35,
            ),
            label: 'Progreso',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              "assets/images/IconRecordOutline.png",
              height: 30,
            ),
            activeIcon: Image.asset(
              "assets/images/IconRecordSolid.png",
              height: 35,
            ),
            label: 'Historial',
          ),
          BottomNavigationBarItem(
            icon: Image.asset("assets/images/IconWaterOutline.png", height: 30),
            activeIcon: Image.asset(
              "assets/images/IconWaterSolid.png",
              height: 35,
            ),
            label: 'Hidratación',
          ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint trackPaint = Paint()
      ..color = Colors.grey[200]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final Paint progressPaint = Paint()
      ..color = Colors.lightBlueAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height * 2);
    
    // Dibuja el fondo del arco (semicírculo completo)
    canvas.drawArc(rect, math.pi, math.pi, false, trackPaint);
    
    // Dibuja el progreso (48% del arco)
    canvas.drawArc(rect, math.pi, math.pi * 0.48, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
