import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class roltrainer extends StatefulWidget {
  const roltrainer({super.key});

  @override
  State<roltrainer> createState() => _roltrainerState();
}

class _roltrainerState extends State<roltrainer> {
  String? rolUser;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    final prefs = await SharedPreferences.getInstance();
    rolUser = prefs.getString('rolUser');
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (rolUser == 'Entrenador') {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Entrenador'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context); // Regresa a la pantalla anterior
            },
          ),
        ),
        body: const Center(
          child: Text(
            'ESTAMOS EN LA SCREEN DEL ENTRENADOR',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else{
      return Scaffold(
        appBar: AppBar(
          title: const Text('Acceso Denegado'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: const Center(
          child: Text(
            'No tienes permisos para ver esta pantalla.',
            style: TextStyle(fontSize: 18, color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
  }
}
