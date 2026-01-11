// lib/layouts/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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

  // Controladores para los datos médicos
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  String? _selectedGender;

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
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _heightController.dispose();
    _weightController.dispose();
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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('accessToken');

      if (token == null) throw Exception("No hay token de autenticación");

      // CONVERSIÓN DE DATOS: Convertir String a Number para el backend
      final double? height = double.tryParse(_heightController.text);
      final double? weight = double.tryParse(_weightController.text);

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
          'date_of_birth': _dobController.text,
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
      return Scaffold(
        appBar: AppBar(
          title: const Text("Tus Datos"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() => _showForm = false),
          ),
        ),
        body: _buildDataCollectionPage(),
      );
    }

    // VISTA DEL CARRUSEL (Basada en Home.dart de la referencia)
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            _buildAppbar(size), // Logo animado superior
            _buildPager(size),  // El PageView con las tarjetas
            _buildPagerIndicator(), // Los puntos inferiores
          ],
        ),
      ),
    );
  }

  // --- WIDGETS DEL CARRUSEL ---

  Widget _buildAppbar(Size size) {
    return Positioned(
      top: 10,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo animado que entra desde arriba
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -100 * (1 - _animation.value)),
                child: Image.asset("assets/images/LogoNEMA.png", height: 40, width: 40, fit: BoxFit.contain),
              );
            },
          ),
          // Botón de saltar
          TextButton(
            onPressed: () => setState(() => _showForm = true),
            child: const Text("Saltar Intro"),
          )
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
                  onPressed: () {
                    // Si es el último slide o el usuario quiere avanzar
                    setState(() {
                      _showForm = true;
                    });
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildPagerIndicator() {
    return Positioned(
      bottom: 20,
      left: 30,
      child: Row(
        children: List.generate(
          _getOnboardingItems().length, 
          (index) => _buildIndicatorDot(index)
        ),
      ),
    );
  }

  Widget _buildIndicatorDot(int index) {
    double animate = _pageOffset - index;
    double size = 10;
    animate = animate.abs();
    Color color = Colors.grey;

    // Lógica para escalar y colorear el punto activo
    if (animate < 1 && animate >= 0) {
      size = 10 + 10 * (1 - animate);
      color = ColorTween(begin: Colors.grey, end: Colors.blue).transform(1 - animate)!;
    }

    return Container(
      margin: const EdgeInsets.all(4),
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20)
      ),
    );
  }

  // DATOS DEL CARRUSEL
  List<OnboardingItem> _getOnboardingItems() {
    return [
      OnboardingItem(
        title: 'Entrena',
        subtitle: 'Inteligente',
        description: 'Tu plan personalizado adaptado por IA para maximizar resultados.',
        mainImage: 'assets/images/EDIA_Text.png', // Usamos tu logo
        iconSmall: Icons.fitness_center,
        iconBlur: Icons.bolt,
        lightColor: Colors.blue.shade300,
        darkColor: Colors.blue.shade900,
      ),
      OnboardingItem(
        title: 'Sigue tu',
        subtitle: 'Progreso',
        description: 'Visualiza tus avances día a día con estadísticas detalladas.',
        mainImage: 'assets/images/EDIA_Text.png',
        iconSmall: Icons.show_chart,
        iconBlur: Icons.timer,
        lightColor: Colors.green.shade300,
        darkColor: Colors.green.shade900,
      ),
      OnboardingItem(
        title: 'Alcanza',
        subtitle: 'Metas',
        description: 'Define tus objetivos y deja que EDIA te guíe hasta ellos.',
        mainImage: 'assets/images/EDIA_Text.png',
        iconSmall: Icons.flag,
        iconBlur: Icons.star,
        lightColor: Colors.orange.shade300,
        darkColor: Colors.orange.shade900,
      ),
    ];
  }

  // --- FORMULARIO DE DATOS (Lógica original mantenida) ---

  Widget _buildDataCollectionPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Cuéntanos sobre ti", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            // Altura
            TextFormField(
              controller: _heightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Altura (cm)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.height)),
              validator: (v) => v!.isEmpty ? "Requerido" : null,
            ),
            const SizedBox(height: 15),

            // Peso
            TextFormField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Peso (kg)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.monitor_weight)),
              validator: (v) => v!.isEmpty ? "Requerido" : null,
            ),
            const SizedBox(height: 15),

            // Género
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: const InputDecoration(labelText: "Género", border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
              items: const [
                DropdownMenuItem(value: "M", child: Text("Masculino")),
                DropdownMenuItem(value: "F", child: Text("Femenino")),
                DropdownMenuItem(value: "O", child: Text("Otro")),
              ],
              onChanged: (v) => setState(() => _selectedGender = v),
              validator: (v) => v == null ? "Requerido" : null,
            ),
            const SizedBox(height: 15),

            // Fecha de Nacimiento
            TextFormField(
              controller: _dobController,
              readOnly: true,
              onTap: () => _selectDate(context),
              decoration: const InputDecoration(labelText: "Fecha de Nacimiento", border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_today)),
              validator: (v) => v!.isEmpty ? "Requerido" : null,
            ),
            
            const SizedBox(height: 40),
            
            _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _submitOnboarding,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text("Finalizar y Entrar"),
                ),
          ],
        ),
      ),
    );
  }
}
