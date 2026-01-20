// lib/layouts/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// Importaciones para el Carrusel
import '../models/onboarding_item.dart';
import '../widgets/onboarding_card.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  // --- VARIABLES PARA EL CARRUSEL ---
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _animation;
  double _pageOffset = 0;
  bool _showForm = false; // Controla si mostramos el carrusel o el formulario

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // --- VARIABLES PARA EL FORMULARIO WIZARD ---
  int _currentStep = 0;
  final int _totalSteps = 3;
  late PageController _formPageController;
  
  // Controladores para los datos médicos
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  String? _selectedGender;
  String _selectedActivityLevel = "Sedentario"; // Valor por defecto

  // URL corregida para el endpoint de onboarding
  final String _apiUrl = "http://10.0.2.2:8000/api/onboarding/"; 

  @override
  void initState() {
    super.initState();
    // Configuración de animaciones del carrusel (Entrada elástica)
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _animation = CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack);
    
    // ViewportFraction 0.8 crea el efecto de ver parte de la siguiente tarjeta
    _pageController = PageController(viewportFraction: 0.8);
    _pageController.addListener(() {
      setState(() {
        _pageOffset = _pageController.page ?? 0;
      });
    });

    _animationController.forward(); // Iniciar animación de entrada
    _formPageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _formPageController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  // Selector de Fecha
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        // Formato YYYY-MM-DD que suele usar Django
        _dobController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  // Enviar datos al backend
  Future<void> _submitOnboarding() async {
    // La validación se hace paso a paso, aquí asumimos que los datos están listos

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('accessToken');

      if (token == null) throw Exception("No hay token de autenticación");

      // CONVERSIÓN DE DATOS: Convertir String a Number para el backend
      final double? height = double.tryParse(_heightController.text);
      final double? weight = double.tryParse(_weightController.text);

      // Guardar datos físicos en SharedPreferences para uso local en la app
      if (height != null) await prefs.setDouble('userHeight', height);
      if (weight != null) await prefs.setDouble('userWeight', weight);
      
      print("Enviando datos a $_apiUrl");

      final response = await http.post( // Cambiado a POST según especificación
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'date_of_birth': _dobController.text,
          'height_cm': height, // Enviamos número
          'weight_kg': weight, // Enviamos número
          'gender': _selectedGender,
          'activity_level': _selectedActivityLevel, // Nuevo campo
          'onboarded': true, // Marcamos como completado
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Éxito
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        _showMessage("Error al guardar datos: ${response.statusCode}", Colors.red);
        _showMessage("Error (${response.statusCode}): Verifica tus datos", Colors.red);
        print("Error Body: ${response.body}");
      }
    } catch (e) {
      _showMessage("Error de conexión: $e", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    // Si ya pasamos el carrusel, mostramos el formulario original
    if (_showForm) {
      return _buildDataCollectionPage();
    }

    // VISTA DEL CARRUSEL (Basada en Home.dart de la referencia)
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            _buildAppbar(size), // Logo animado superior
            _buildPager(size),  // El PageView con las tarjetas
            _buildSkipButton(), // Botón de imagen para saltar
          ],
        ),
      ),
    );
  }

  // --- WIDGETS DEL CARRUSEL ---

  Widget _buildAppbar(Size size) {
    return Positioned(
      top: 10,
      left: 10,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF154950), size: 30),
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          ),
          // Logo animado que entra desde arriba
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -100 * (1 - _animation.value)),
                child: Image.asset("assets/images/LogoNEMAsinTexto.png", height: 65, width:235, fit: BoxFit.contain),
              );
            },
          ),
        ],
      )
    );
  }

  Widget _buildPager(Size size) {
    return Container(
      margin: const EdgeInsets.only(top: 70), // Espacio para el AppBar
      height: size.height - 100, // Altura disponible
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          // Animación de entrada lateral de todo el carrusel
          return Transform.translate(
            offset: Offset(400 * (1 - _animation.value), 0),
            child: PageView.builder(
              controller: _pageController,
              itemCount: _getOnboardingItems().length,
              itemBuilder: (context, index) {
                return OnboardingCard(
                  item: _getOnboardingItems()[index],
                  pageOffset: _pageOffset,
                  index: index,
                  
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkipButton() {
    return Positioned(
      bottom: 30,
      left: 30,
      right: 30,
      child: SizedBox(
        height: 55,
        child: ElevatedButton(
          onPressed: () => setState(() => _showForm = true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF154950), // Color oscuro de la paleta
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 5,
          ),
          child: Text(
            "Siguiente",
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  // DATOS DEL CARRUSEL
  List<OnboardingItem> _getOnboardingItems() {
    return [
      OnboardingItem(
        title: 'Entrena',
        subtitle: 'Inteligente',
        description: 'NEMA crea rutinas personalizadas usando tus datos diarios y adapta cada entrenamiento según tu rendimiento real.',
        mainImage: 'assets/images/CardEntrenaInteligente.png', // Usamos tu logo
        iconSmall: Icons.fitness_center,
        iconBlur: Icons.bolt,
        lightColor: Colors.blue.shade300,
        darkColor: Colors.blue.shade900,
      ),
      OnboardingItem(
        title: '   Sigue tu',
        subtitle: 'Progreso',
        description: 'Monitorea tu evolución día a día con gráficos claros y análisis inteligentes que revelan cómo avanzas realmente.',
        mainImage: 'assets/images/CardSiguetuProgreso.png',
        iconSmall: Icons.show_chart,
        iconBlur: Icons.timer,
        lightColor: Colors.green.shade300,
        darkColor: Colors.green.shade900,
      ),
      OnboardingItem(
        title: 'Alcanza tus',
        subtitle: 'Metas',
        description: 'Define tus objetivos y deja que NEMA te guíe con ajustes inteligentes y motivación constante.',
        mainImage: 'assets/images/CardAlcanzatusMetas.png',
        iconSmall: Icons.flag,
        iconBlur: Icons.star,
        lightColor: Colors.orange.shade300,
        darkColor: Colors.orange.shade900,
      ),
    ];
  }

  // --- NUEVO FORMULARIO WIZARD (DARK MODE) ---

  void _nextStep() {
    // Validaciones simples por paso
    if (_currentStep == 0) {
      if (_selectedGender == null) {
        _showMessage("Por favor selecciona tu sexo", Colors.orange);
        return;
      }
      if (_dobController.text.isEmpty) {
        _showMessage("Por favor ingresa tu fecha de nacimiento", Colors.orange);
        return;
      }
    } else if (_currentStep == 1) {
      if (_heightController.text.isEmpty || _weightController.text.isEmpty) {
        _showMessage("Por favor completa tus medidas", Colors.orange);
        return;
      }
    }

    if (_currentStep < _totalSteps - 1) {
      _formPageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      _submitOnboarding();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _formPageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    } else {
      setState(() => _showForm = false); // Volver al carrusel
    }
  }

  Widget _buildDataCollectionPage() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Barra de Progreso Superior
            LinearProgressIndicator(
              value: (_currentStep + 1) / _totalSteps,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
              minHeight: 6,
            ),
            
            Expanded(
              child: PageView(
                controller: _formPageController,
                physics: const NeverScrollableScrollPhysics(), // Bloquear scroll manual
                children: [
                  _buildStep1BasicInfo(),
                  _buildStep2PhysicalMeasures(),
                  _buildStep3ActivityLevel(),
                ],
              ),
            ),
            
            // Barra de Navegación Inferior
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  // Botón Atrás (Circular)
                  InkWell(
                    onTap: _prevStep,
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                        color: Colors.grey[200],
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.black54),
                    ),
                  ),
                  const SizedBox(width: 15),
                  // Botón Siguiente (Píldora expandida)
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _nextStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6), // Azul brillante
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              _currentStep == _totalSteps - 1 ? "FINALIZAR" : "SIGUIENTE",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- PASO 1: DATOS BÁSICOS ---
  Widget _buildStep1BasicInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Háblanos un poco de ti", style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF134E5e))),
          const SizedBox(height: 10),
          Text("Para personalizar tu experiencia", style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600])),
          const SizedBox(height: 40),
          
          // Selector de Sexo
          Text("Sexo biológico", style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w600)),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: _buildGenderCard("Hombre", "M")),
              const SizedBox(width: 15),
              Expanded(child: _buildGenderCard("Mujer", "F")),
            ],
          ),
          
          const SizedBox(height: 30),
          
          // Campo de Fecha de Nacimiento (Reemplaza Edad)
          _buildStyledInput(
            label: "Fecha de Nacimiento",
            controller: _dobController,
            readOnly: true,
            onTap: () => _selectDate(context),
            suffix: "📅",
          
          ),
        ],
      ),
    );
  }

  Widget _buildGenderCard(String label, String value) {
    bool isSelected = _selectedGender == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedGender = value),
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(15),
          border: isSelected ? Border.all(color: const Color(0xFF3B82F6), width: 2) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.w500)),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? const Color(0xFF3B82F6) : Colors.grey),
                color: isSelected ? const Color(0xFF3B82F6) : null,
              ),
              child: isSelected ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
            )
          ],
        ),
      ),
    );
  }

  // --- PASO 2: MEDIDAS FÍSICAS ---
  Widget _buildStep2PhysicalMeasures() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Un par de preguntas más", style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF134E5e))),
          
          const SizedBox(height: 10),
          Text("Esto nos ayuda a calcular tus necesidades", style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600])),
          const SizedBox(height: 40),

          _buildStyledInput(
            label: "¿Cuánto mides?",
            controller: _heightController,
            isNumber: true,
            suffix: "CM",
          ),
          const SizedBox(height: 20),
          _buildStyledInput(
            label: "Peso actual",
            controller: _weightController,
            isNumber: true,
            suffix: "KG",
          ),
          const SizedBox(height: 10),
          Text("Podrás cambiar esto más tarde en tu perfil.", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  // --- PASO 3: NIVEL DE ACTIVIDAD ---
  Widget _buildStep3ActivityLevel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("¿Cuál es su nivel de actividad básico?", style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: const Color(0xFF134E5E))),
          const SizedBox(height: 10),
          Text("Sin contar tus entrenamientos", style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600])),
          const SizedBox(height: 30),

          _buildActivityCard("Sedentario", "Pasa la mayor parte del día sentado"),
          _buildActivityCard("Ligeramente activo", "Pasa buena parte del día de pie"),
          _buildActivityCard("Moderadamente activo", "Actividad física moderada diaria"),
          _buildActivityCard("Muy activo", "Trabajo físico intenso o mucho movimiento"),
        ],
      ),
    );
  }

  Widget _buildActivityCard(String title, String description) {
    bool isSelected = _selectedActivityLevel == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedActivityLevel = title),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? Border.all(color: const Color(0xFF3B82F6), width: 2) : Border.all(color: Colors.transparent, width: 2),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 5),
                  Text(description, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
                border: Border.all(color: isSelected ? const Color(0xFF3B82F6) : Colors.grey),
              ),
              child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
            )
          ],
        ),
      ),
    );
  }

  // --- WIDGET AUXILIAR PARA INPUTS ---
  Widget _buildStyledInput({
    required String label,
    required TextEditingController controller,
    bool isNumber = false,
    String? suffix,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(15),
          ),
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            onTap: onTap,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            // Restricción estricta: Solo dígitos, sin puntos ni comas
            inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : [],
            style: GoogleFonts.poppins(color: Colors.black87, fontSize: 18),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              suffixIcon: suffix != null 
                ? Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Text(suffix, style: GoogleFonts.poppins(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                  ) 
                : null,
            ),
          ),
        ),
      ],
    );
  }
}
