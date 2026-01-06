import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // Controladores de formulario
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? _selectedGender;
  bool _isLoading = false;

  final String _apiUrl = "http://10.0.2.2:8000/api/users/onboarding/";

  @override
  void dispose() {
    _dateController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  // Seleccionar fecha de nacimiento
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // Validaciones
  String? _validateDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, selecciona tu fecha de nacimiento';
    }
    try {
      DateTime.parse(value);
      return null;
    } catch (e) {
      return 'Fecha inválida';
    }
  }

  String? _validateHeight(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, ingresa tu altura';
    }
    try {
      final height = double.parse(value);
      if (height < 100 || height > 250) {
        return 'La altura debe estar entre 100 y 250 cm';
      }
      return null;
    } catch (e) {
      return 'Ingresa un número válido';
    }
  }

  String? _validateWeight(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, ingresa tu peso';
    }
    try {
      final weight = double.parse(value);
      if (weight < 20 || weight > 300) {
        return 'El peso debe estar entre 20 y 300 kg';
      }
      return null;
    } catch (e) {
      return 'Ingresa un número válido';
    }
  }

  String? _validateGender(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, selecciona tu género';
    }
    return null;
  }

  // Enviar datos al backend
  Future<void> _submitOnboarding() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Usar el ApiService para enviar los datos
      final response = await ApiService.submitOnboarding(
        dateOfBirth: _dateController.text,
        height: double.parse(_heightController.text),
        weight: double.parse(_weightController.text),
        gender: _selectedGender!,
      );

      setState(() {
        _isLoading = false;
      });

      if (response.success) {
        // Onboarding exitoso
        // Guardar en storage que el usuario ya completó onboarding
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('onboarded', true);
        
        print('Onboarding completado exitosamente');
        
        _showMessage('¡Perfil completado! Bienvenido a EDIA', Colors.green);

        if (!mounted) return;
        // Redirigir a la pantalla principal
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // Error en la solicitud
        _showMessage(response.error ?? 'Error desconocido', Colors.red);
        print('Error en onboarding: ${response.error}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showMessage('Error de conexión: $e', Colors.red);
      print('Excepción durante onboarding: $e');
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completa tu Perfil'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Bienvenida y explicación
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue, width: 1),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.info, color: Colors.blue, size: 32),
                    SizedBox(height: 12),
                    Text(
                      '¡Bienvenido a EDIA!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Para brindarte una experiencia personalizada, necesitamos algunos datos sobre ti. Esta información nos ayudará a crear planes de entrenamiento adaptados a tu perfil.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Fecha de Nacimiento
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Fecha de Nacimiento',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _dateController,
                readOnly: true,
                decoration: InputDecoration(
                  hintText: 'Selecciona tu fecha de nacimiento',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.calendar_today),
                  suffixIcon: GestureDetector(
                    onTap: () => _selectDate(context),
                    child: const Icon(Icons.edit, color: Colors.blue),
                  ),
                ),
                onTap: () => _selectDate(context),
                validator: _validateDate,
              ),
              const SizedBox(height: 20),

              // Altura
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Altura (cm)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _heightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Ej: 180',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.height),
                  suffixText: 'cm',
                ),
                validator: _validateHeight,
              ),
              const SizedBox(height: 20),

              // Peso
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Peso (kg)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Ej: 75.5',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.monitor_weight),
                  suffixText: 'kg',
                ),
                validator: _validateWeight,
              ),
              const SizedBox(height: 20),

              // Género
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Género',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                items: const [
                  DropdownMenuItem(value: 'M', child: Text('Masculino')),
                  DropdownMenuItem(value: 'F', child: Text('Femenino')),
                  DropdownMenuItem(value: 'O', child: Text('Otro')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value;
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.person),
                  hintText: 'Selecciona tu género',
                ),
                validator: _validateGender,
              ),
              const SizedBox(height: 40),

              // Botón enviar
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitOnboarding,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Completar Perfil',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
              const SizedBox(height: 20),
              const Text(
                'Puedes actualizar esta información más tarde en tu perfil',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
