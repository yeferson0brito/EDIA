import 'package:flutter/material.dart';
import 'layouts/home_screen.dart';
import 'layouts/register_screen.dart';
import 'layouts/login_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(

      home: LoginScreen(), // La pantalla de inicio será el login
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/home': (context) => Login(),
        // Aquí puedes añadir más rutas, como la pantalla de inicio después del login
        // '/home': (context) => HomeScreen(),
      },  
    );
  }
}

/*      home: Scaffold(
        appBar: AppBar(backgroundColor: Colors.blue, toolbarHeight: 35,),
        body: RegisterScreen(),
      ),
*/