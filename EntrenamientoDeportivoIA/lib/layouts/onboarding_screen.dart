// lib/layouts/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  int _currentPage = 0;

  // Controladores para los datos médicos
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  String? _selectedGender;

  // URL corregida para el endpoint de onboarding
  final String _apiUrl = "http://10.0.2.2:8000/api/onboarding/"; 

  @override
  void dispose() {
    _pageController.dispose();
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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  // PÁGINA 1: TUTORIAL / BIENVENIDA
                  _buildWelcomePage(),
                  // PÁGINA 2: RECOLECCIÓN DE DATOS
                  _buildDataCollectionPage(),
                ],
              ),
            ),
            // Indicadores de página (puntos)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(2, (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index ? Colors.blue : Colors.grey,
                ),
              )),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset("assets/images/EDIA_Text.png", height: 100), // Tu logo
          const SizedBox(height: 40),
          const Text(
            "¡Bienvenido a EDIA!",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          const SizedBox(height: 20),
          const Text(
            "Tu entrenador personal con Inteligencia Artificial.\n\nAntes de comenzar, necesitamos conocerte un poco mejor para adaptar tus entrenamientos.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            child: const Text("Comenzar"),
          ),
        ],
      ),
    );
  }

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
