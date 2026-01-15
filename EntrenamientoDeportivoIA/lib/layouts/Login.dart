import 'package:flutter/material.dart';

class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bienvenido'), 
        automaticallyImplyLeading:
            false,
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Image.asset("assets/images/Logo.PNG"),
          ),
          //Image.network("https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSRRckyaWGMkFa9aRiYLT4kKFUIwB3nW21LBA&s"),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Nombre",
                prefixIcon: Icon(Icons.face_rounded),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.add_call),
                hintText: "Numero de Telefono",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.email),
                hintText: "Correo electronico",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              obscureText: true,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.lock),
                hintText: "Contraseña",
                border: OutlineInputBorder(),
              ),
            ),
          ),

          ElevatedButton(
            onPressed: () {},
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.blue),
              foregroundColor: WidgetStateProperty.all(Colors.black54),
              textStyle: WidgetStateProperty.all(
                TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            child: Text("Iniciar Sesion"),
          ),

          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/register');
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.grey),
              foregroundColor: WidgetStateProperty.all(Colors.black54),
              textStyle: WidgetStateProperty.all(
                TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            child: Text("Crear Cuenta"),
          ),
        ],
      ),
    );
  }
}
