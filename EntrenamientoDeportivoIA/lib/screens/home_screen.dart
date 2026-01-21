import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui'; // Para ImageFilter (Blur)
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:confetti/confetti.dart';

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

  // Variables para el podómetro
  late Stream<StepCount> _stepCountStream;
  int _steps = 0;
  int _lastSensorReading = -1; // Última lectura del sensor guardada
  String _lastDate = ""; // Fecha de la última actualización
  final int _stepGoal = 100; // Objetivo solicitado
  
  late ConfettiController _confettiController;
  bool _stepGoalReached = false;

  // Variables para Hidratación
  int _waterIntake = 0;
  final int _waterGoal = 3200;
  bool _waterGoalReached = false;

  // Variables para datos físicos del usuario
  double? _userHeight; // en cm
  double? _userWeight; // en kg

  // Timer para actualizar la tarjeta de sueño en tiempo real
  Timer? _timer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _loadUserData();
    _loadUserPhysicalData();
    _loadHydrationData();
    _initPedometer();
    _startClock();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _startClock() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  Future<void> _initPedometer() async {
    // Cargar datos guardados
    final prefs = await SharedPreferences.getInstance();
    _steps = prefs.getInt('dailySteps') ?? 0;
    _lastSensorReading = prefs.getInt('lastSensorReading') ?? -1;
    _lastDate = prefs.getString('lastDate') ?? DateTime.now().toString().substring(0, 10);

    // Verificar si cambió el día
    String today = DateTime.now().toString().substring(0, 10);
    if (_lastDate != today) {
      _steps = 0;
      _lastDate = today;
      _lastSensorReading = -1;
      _stepGoalReached = false;
      await _saveStepData();
    } else {
      _stepGoalReached = _steps >= _stepGoal;
    }

    setState(() {}); // Actualizar UI con datos cargados

    // Solicitar permisos de actividad física (necesario para Android 10+)
    var status = await Permission.activityRecognition.status;
    if (status.isDenied || status.isRestricted || status.isPermanentlyDenied) {
      status = await Permission.activityRecognition.request();
    }

    if (status.isGranted) {
      _stepCountStream = Pedometer.stepCountStream;
      _stepCountStream.listen(_onStepCount).onError(_onStepCountError);
    }
  }

  void _onStepCount(StepCount event) {
    int sensorSteps = event.steps;
    String today = DateTime.now().toString().substring(0, 10);

    setState(() {
      if (_lastDate != today) {
        // Nuevo día: reiniciar
        _steps = 0;
        _lastDate = today;
        _lastSensorReading = sensorSteps;
      } else {
        // Mismo día: acumular diferencia
        if (_lastSensorReading == -1) {
          _lastSensorReading = sensorSteps;
        }
        int delta = sensorSteps - _lastSensorReading;
        // Detectar reinicio del dispositivo (delta negativo)
        if (delta < 0) {
          delta = sensorSteps;
        }
        _steps += delta;
        _lastSensorReading = sensorSteps;
      }

      // Verificar meta de pasos para confeti
      if (_steps >= _stepGoal && !_stepGoalReached) {
        _stepGoalReached = true;
        _confettiController.play();
      }
    });
    _saveStepData();
  }

  Future<void> _saveStepData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dailySteps', _steps);
    await prefs.setInt('lastSensorReading', _lastSensorReading);
    await prefs.setString('lastDate', _lastDate);
  }

  void _onStepCountError(error) {
    print('Error en podómetro: $error');
  }

  // --- LÓGICA DE HIDRATACIÓN ---
  Future<void> _loadHydrationData() async {
    final prefs = await SharedPreferences.getInstance();
    String today = DateTime.now().toString().substring(0, 10);
    String savedDate = prefs.getString('lastWaterDate') ?? today;

    setState(() {
      if (savedDate != today) {
        _waterIntake = 0; // Reiniciar si es otro día
        _waterGoalReached = false;
        prefs.setString('lastWaterDate', today);
        prefs.setInt('dailyWater', 0);
      } else {
        _waterIntake = prefs.getInt('dailyWater') ?? 0;
        _waterGoalReached = _waterIntake >= _waterGoal;
      }
    });
  }

  Future<void> _addWater(int amount) async {
    setState(() {
      _waterIntake += amount;
      if (_waterIntake >= _waterGoal && !_waterGoalReached) {
        _waterGoalReached = true;
        _confettiController.play();
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dailyWater', _waterIntake);
    
    // Actualizar fecha por si acaso
    String today = DateTime.now().toString().substring(0, 10);
    await prefs.setString('lastWaterDate', today);
  }

  Future<void> _loadUserPhysicalData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userHeight = prefs.getDouble('userHeight');
      _userWeight = prefs.getDouble('userWeight');
    });
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
    double progress = (_steps / _stepGoal).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: _showStepsDetailDialog,
      child: Container(
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
          const Icon(Icons.directions_walk, color: Color(0xFF134E5E)),
          const SizedBox(width: 10),
          Text(
            'Pasos',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
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
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor: Colors.grey[200],
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFF134E5E)),
                ),
              ),
              // Contador en el medio
              Text(
                '$_steps',
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
            'Objetivo: $_stepGoal',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      ),
    );
  }

  // TARJETA DE HIDRATACIÓN (Reemplaza Calorías)
  Widget _buildHydrationCard() {
    double progress = (_waterIntake / _waterGoal).clamp(0.0, 1.0);

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
                  '${(progress * 100).toInt()}%',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF134E5E),
                  ),
                ),
                Text(
                  '${_waterIntake}ml / ${_waterGoal}ml',
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
                        painter: _ArcPainter(progress: progress),
                      ),
                      Positioned(
                        bottom: 0,
                        child: GestureDetector(
                          onTap: _showCupSelectionDialog,
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

  // --- DIALOGO DE SELECCIÓN DE TAZA ---
  void _showCupSelectionDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4), // Opacidad del fondo
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Difuminado
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            child: Container(
              padding: const EdgeInsets.all(20),
              width: MediaQuery.of(context).size.width * 0.85,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Cambiar Taza',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF134E5E),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 3,
                    mainAxisSpacing: 15,
                    crossAxisSpacing: 15,
                    childAspectRatio: 0.8,
                    children: [
                      _buildCupOption(Icons.coffee, '100 ml', 100),
                      _buildCupOption(Icons.local_drink, '200 ml', 200),
                      _buildCupOption(Icons.emoji_food_beverage, '300 ml', 300),
                      _buildCupOption(Icons.water_drop, '400 ml', 400),
                      _buildCupOption(Icons.water_drop_outlined, '500 ml', 500), // Icono más grande visualmente
                      _buildCupOption(Icons.local_bar, '1000 ml', 1000),
                      _buildCupOption(Icons.add_circle_outline, 'Otro', 0),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancelar',
                      style: GoogleFonts.poppins(color: Colors.grey),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCupOption(IconData icon, String label, int amount) {
    return GestureDetector(
      onTap: () {
        if (amount > 0) {
          _addWater(amount);
          Navigator.pop(context);
        } else {
          Navigator.pop(context);
          _showCustomWaterSlider();
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.blue, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomWaterSlider() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (BuildContext context) {
        double currentVal = 250; // Valor inicial
        const double maxVal = 3000;

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                backgroundColor: Colors.white,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  height: 450,
                  width: MediaQuery.of(context).size.width * 0.85,
                  child: Column(
                    children: [
                      Text(
                        'Personalizar',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF134E5E),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Desliza para ajustar',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // BARRA TIPO VOLUMEN
                            GestureDetector(
                              onVerticalDragUpdate: (details) {
                                setState(() {
                                  currentVal -= details.delta.dy * 2; // Sensibilidad
                                  currentVal = currentVal.clamp(0.0, maxVal);
                                });
                              },
                              child: Container(
                                width: 70,
                                height: 280,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(35),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(35),
                                  child: _WaterWaveWidget(
                                    percentage: currentVal / maxVal,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 40),
                            // NUMERO A LA DERECHA
                            SizedBox(
                              width: 120, // Ancho fijo para evitar que la barra se mueva al cambiar los dígitos
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${currentVal.toInt()}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 42,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF134E5E),
                                    ),
                                  ),
                                  Text(
                                    'ml',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancelar', style: GoogleFonts.poppins(color: Colors.grey)),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              _addWater(currentVal.toInt());
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF134E5E),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text('Agregar', style: GoogleFonts.poppins(color: Colors.white)),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // TARJETA DE INTENSIDAD DEL DÍA (Reemplaza Próximo Entreno)
  Widget _buildIntensityCard() {
    return GestureDetector(
      onTap: _showIntensityDetailDialog,
      child: Container(
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
          const SizedBox(height: 5),
          // Lista de ejercicios de ejemplo (Modelo Base)
          _buildExerciseItem(Icons.directions_run, 'Caminata', '30 min'),
          const SizedBox(height: 5),
          _buildExerciseItem(Icons.pool, 'Natación', '30 min'),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Detalles',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: const Color(0xFF134E5E).withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 5), 
              const Icon(
                Icons.more_horiz,
                color: Color(0xFF134E5E),
              ),
            ],
          ),
        ],
      ),
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

  // --- DIALOGO DE DETALLE DE PASOS ---
  void _showStepsDetailDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (BuildContext context) {
        double progress = (_steps / _stepGoal).clamp(0.0, 1.0);
        double km;
        int calories;

        // Camino 1: Si hay datos de usuario, usar cálculos personalizados
        if (_userHeight != null && _userWeight != null) {
          // Zancada = altura * 0.415. Dividimos por 100 para m, luego por 1000 para km.
          double strideInMeters = (_userHeight! * 0.415) / 100;
          km = (_steps * strideInMeters) / 1000;
          // Calorías: Estimación simple basada en peso. (Ej: 0.0005 kcal por paso por kg)
          calories = (_steps * _userWeight! * 0.0005).toInt();
        } else {
          // Camino 2: Si no hay login (modo dev), usar estimaciones generales
          km = _steps * 0.000762; // Zancada promedio de 76.2cm
          calories = (_steps * 0.04).toInt(); // 0.04 kcal por paso
        }

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            child: Container(
              padding: const EdgeInsets.all(20),
              width: MediaQuery.of(context).size.width * 0.85,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Detalle de Pasos',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF134E5E),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 120,
                    width: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          height: 120,
                          width: 120,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 10,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF134E5E)),
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.directions_walk, size: 30, color: Color(0xFF134E5E)),
                            Text(
                              '$_steps',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF134E5E),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(Icons.map, '${km.toStringAsFixed(2)} km', 'Distancia'),
                      _buildStatItem(Icons.local_fire_department, '$calories kcal', 'Calorías'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cerrar',
                      style: GoogleFonts.poppins(color: Colors.grey),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600], size: 24),
        const SizedBox(height: 5),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF134E5E),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  // --- DIALOGO DE INTENSIDAD ---
  void _showIntensityDetailDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            child: Container(
              padding: const EdgeInsets.all(20),
              width: MediaQuery.of(context).size.width * 0.85,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Intensidad del Día',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF134E5E),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Ejercicios recomendados basados en tu nivel',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  // Lista expandida de ejemplo
                  _buildExerciseItem(Icons.directions_run, 'Elíptica', '30 min'),
                  const SizedBox(height: 10),
                  _buildExerciseItem(Icons.pool, 'Natación', '30 min'),
                  const SizedBox(height: 10),
                  _buildExerciseItem(Icons.fitness_center, 'Pesas', '20 min'),
                  const SizedBox(height: 10),
                  _buildExerciseItem(Icons.self_improvement, 'Yoga', '15 min'),
                  
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cerrar',
                      style: GoogleFonts.poppins(color: Colors.grey),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // TARJETA DE SUEÑO (Métricas y Registro)
  Widget _buildSleepCard() {
    DateTime now = _currentTime;
    
    // Definir horario de sueño (1:00 AM - 7:00 AM)
    DateTime todaySleep = DateTime(now.year, now.month, now.day, 1, 0); 
    DateTime todayWake = DateTime(now.year, now.month, now.day, 7, 0);
    
    String message = "";
    String title = "";
    Duration remaining;
    String bgImage = "";
    
    // Lógica de estados
    if (now.isAfter(todaySleep) && now.isBefore(todayWake)) {
      // CASO 5: En horario de sueño (01:00 - 07:00)
      message = "¡Ey!, Deberias estar durmiendo, todo bien?";
      title = "Tiempo hasta tu hora de levantarse";
      remaining = todayWake.difference(now);
    } else {
      // Horario despierto
      title = "Tiempo hasta tu hora de dormir";
      
      // Calcular próxima hora de dormir
      DateTime nextSleep = (now.isBefore(todaySleep)) 
          ? todaySleep // Si es 00:30, la hora es hoy a la 1:00
          : todaySleep.add(const Duration(days: 1)); // Si es 08:00, es mañana a la 1:00
          
      remaining = nextSleep.difference(now);
      
      if (remaining.inHours < 1) {
        // CASO 4: Menos de 1 hora
        message = "Hora de ir a la cama";
      } else if (remaining.inHours < 4) {
        // CASO 3: Menos de 4 horas
        message = "Se aproxima la hora del sueño, ¿nos preparamos?";
      } else if (now.hour >= 7 && now.hour < 12) {
        // CASO 1: Mañana (07:00 - 12:00)
        message = "Buenos dias!";
      } else {
        // CASO 2: Tarde (12:00 - 21:00 aprox)
        message = "¡Hey!, Se nos va el día.";
      }
    }

    // Selección de imagen según la hora
    int hour = now.hour;
    if (hour >= 6 && hour < 12) {
      bgImage = 'assets/images/ImageBoardSleepMorning.png';
    } else if (hour >= 12 && hour < 16) {
      bgImage = 'assets/images/ImageBoardSleepMidday.png';
    } else if (hour >= 16 && hour < 20) {
      bgImage = 'assets/images/ImageBoardSleepAfternoon.png';
    } else {
      bgImage = 'assets/images/ImageBoardSleep.png';
    }

    String countdown = "${remaining.inHours}h ${remaining.inMinutes.remainder(60)}m";

    return GestureDetector(
      onTap: _showSleepDetailDialog,
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            image: AssetImage(bgImage),
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
              colors: [Colors.black.withOpacity(0.8), Colors.transparent],
            ),
          ),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  const Icon(Icons.bedtime, color: Colors.white, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                countdown,
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                message,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- DIALOGO DE DETALLE DE SUEÑO ---
  void _showSleepDetailDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            child: Container(
              padding: const EdgeInsets.all(20),
              width: MediaQuery.of(context).size.width * 0.85,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Análisis de Sueño',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF134E5E),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Resumen de tu última noche',
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  // Gráfico circular simulado o estadísticas
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildSleepStatItem('Profundo', '1h 45m', Colors.indigo),
                      _buildSleepStatItem('Ligero', '4h 30m', Colors.blue),
                      _buildSleepStatItem('REM', '1h 15m', Colors.lightBlueAccent),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  _buildSleepTimeRow(Icons.bedtime, 'Hora de dormir', '23:15'),
                  _buildSleepTimeRow(Icons.wb_sunny, 'Hora de despertar', '06:45'),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cerrar',
                      style: GoogleFonts.poppins(color: Colors.grey),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSleepStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          height: 12,
          width: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF134E5E),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSleepTimeRow(IconData icon, String label, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF134E5E), size: 20),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
          Text(
            time,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF134E5E),
            ),
          ),
        ],
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
              leading: const Icon(Icons.group, color: Color(0xFF134E5E)),
              title: Text(
                'Entrenadores',
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
            child: Stack(
              children: [
                Padding(
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
                // Confetti Widget en la parte superior del Stack
                Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    shouldLoop: false,
                    colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
                  ),
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
  final double progress;

  _ArcPainter({required this.progress});

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
    canvas.drawArc(rect, math.pi, math.pi * progress, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WaterWaveWidget extends StatefulWidget {
  final double percentage;
  final Color color;

  const _WaterWaveWidget({required this.percentage, required this.color});

  @override
  State<_WaterWaveWidget> createState() => _WaterWaveWidgetState();
}

class _WaterWaveWidgetState extends State<_WaterWaveWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _WavePainter(
            percentage: widget.percentage,
            animationValue: _controller.value,
            color: widget.color,
          ),
          child: Container(),
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  final double percentage;
  final double animationValue;
  final Color color;

  _WavePainter({required this.percentage, required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final double waterHeight = size.height * percentage;
    final double baseHeight = size.height - waterHeight;

    if (percentage == 0) return;
    if (percentage == 1) {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
      return;
    }

    path.moveTo(0, baseHeight);
    
    
    double amplitude = 3.5;
    double frequency = 1.5; 
    
    for (double x = 0; x <= size.width; x++) {
      double y = amplitude * math.sin((x / size.width * 2 * math.pi * frequency) + (animationValue * 2 * math.pi));
      path.lineTo(x, baseHeight + y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.percentage != percentage || oldDelegate.animationValue != animationValue;
  }
}