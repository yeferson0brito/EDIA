import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Configura un temporizador de 3 segundos
    Timer(const Duration(seconds: 2), () {
      // MODO DESARROLLO: Navega directo a '/home' saltando el login
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');//Remplazar luego por login
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Puedes cambiar el color de fondo si lo deseas
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Image.asset(
            "assets/images/LogoNEMA.png", // Imagen de carga
          ),
        ),
      ),
    );
  }
}
