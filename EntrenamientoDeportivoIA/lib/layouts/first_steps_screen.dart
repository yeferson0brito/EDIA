import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FirstStepsScreen extends StatefulWidget {
  const FirstStepsScreen({super.key});

  @override
  State<FirstStepsScreen> createState() => _FirstStepsScreenState();
}

class _FirstStepsScreenState extends State<FirstStepsScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _dob;
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  String _gender = 'M';
  bool _isLoading = false;

  final String _getUrl = 'http://10.0.2.2:8000/api/users/onboarding/';
  final String _postUrl = 'http://10.0.2.2:8000/api/users/onboarding/';

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    // Pre-fill form if backend provides data
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    if (token == null) return;

    try {
      final resp = await http.get(
        Uri.parse(_getUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        setState(() {
          if (data['date_of_birth'] != null) {
            _dob = DateTime.tryParse(data['date_of_birth']);
          }
          if (data['height_cm'] != null) {
            _heightController.text = data['height_cm'].toString();
          }
          if (data['weight_kg'] != null) {
            _weightController.text = data['weight_kg'].toString();
          }
          if (data['gender'] != null) {
            _gender = data['gender'].toString();
          }
        });
      } else if (resp.statusCode == 401) {
        _showMessage('Sesión expirada. Por favor ingresa de nuevo.', Colors.red);
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      // ignore, leave form empty
      print('Error al obtener profile: $e');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
      _showMessage('Por favor, selecciona una fecha de nacimiento válida.', Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    if (token == null) {
      _showMessage('Token no disponible. Vuelve a iniciar sesión.', Colors.red);
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    final payload = {
      'date_of_birth': _dob!.toIso8601String().split('T').first,
      'height_cm': int.tryParse(_heightController.text) ?? 0,
      'weight_kg': double.tryParse(_weightController.text) ?? 0.0,
      'gender': _gender,
    };

    try {
      final resp = await http.post(
        Uri.parse(_postUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      setState(() => _isLoading = false);

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final data = jsonDecode(resp.body);
        // Mark onboarded locally
        await prefs.setBool('onboarded', true);
        // Optionally update saved profile fields
        if (data['onboarded'] == true) {
          _showMessage('Onboarding completado', Colors.green);
        }
        Navigator.pushReplacementNamed(context, '/home');
      } else if (resp.statusCode == 400) {
        final data = jsonDecode(resp.body);
        String msg = 'Datos inválidos';
        if (data is Map && data.containsKey('detail')) msg = data['detail'];
        _showMessage(msg, Colors.red);
      } else if (resp.statusCode == 401) {
        _showMessage('No autorizado. Por favor ingresa de nuevo.', Colors.red);
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        _showMessage('Error del servidor: ${resp.statusCode}', Colors.red);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage('Error de conexión: $e', Colors.red);
    }
  }

  void _showMessage(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _dob ?? DateTime(now.year - 25);
    final firstDate = DateTime(now.year - 120);
    final lastDate = DateTime(now.year - 10);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Primeros pasos')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Bienvenido a EDIA',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Antes de comenzar necesitamos algunos datos para personalizar tu experiencia.',
              ),
              const SizedBox(height: 20),

              // Fecha de nacimiento
              const Text('Fecha de nacimiento'),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  child: Text(_dob == null ? 'Seleccionar fecha' : '${_dob!.toLocal().toIso8601String().split('T').first}'),
                ),
              ),
              const SizedBox(height: 12),

              // Altura
              TextFormField(
                controller: _heightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Altura (cm)', border: OutlineInputBorder()),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingresa tu altura';
                  final n = int.tryParse(v);
                  if (n == null) return 'Altura inválida';
                  if (n < 50 || n > 300) return 'Altura fuera de rango';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Peso
              TextFormField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Peso (kg)', border: OutlineInputBorder()),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingresa tu peso';
                  final n = double.tryParse(v);
                  if (n == null) return 'Peso inválido';
                  if (n < 20 || n > 300) return 'Peso fuera de rango';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Género
              DropdownButtonFormField<String>(
                value: _gender,
                items: const [
                  DropdownMenuItem(value: 'M', child: Text('Masculino')),
                  DropdownMenuItem(value: 'F', child: Text('Femenino')),
                  DropdownMenuItem(value: 'O', child: Text('Otro')),
                ],
                onChanged: (v) => setState(() => _gender = v ?? 'M'),
                decoration: const InputDecoration(labelText: 'Género', border: OutlineInputBorder()),
              ),

              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submit,
                        child: const Text('Continuar'),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
