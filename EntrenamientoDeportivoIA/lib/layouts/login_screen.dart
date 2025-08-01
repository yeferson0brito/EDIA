//IMPORTACIONES******************************************************************************************************
// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
// Necesitaremos el paquete HTTP para la comunicación con el backend
import 'package:http/http.dart' as http;
import 'dart:convert'; // Para convertir los formatos de JSON
import 'package:shared_preferences/shared_preferences.dart'; // Para guardar el token

//IMPORTACIONES--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//LLAMADO************************************************************************************************************
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

//LLAMADO--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

class _LoginScreenState extends State<LoginScreen> {
  //CONTROLADORES PARA CADA CAMPO****************************************************************************************************
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>(); // Clave para validar el formulario
  bool _isLoading = false; // Estado para mostrar un indicador de carga

  //URL de la API de Django
  final String _apiUrl = "http://10.0.2.2:8000/api/login/";

  //----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

  //FUNCION PARA EL LOGIN DE USUARIOS**********************************************************************************
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return; // Si el formulario no es válido, no hacemos nada
    }

    setState(() {
      _isLoading = true; // Iniciamos el indicador de carga
    });
    //ENVIAR DATOS AL SERVIDOR*****************************************************************************
    //Se obtienen los valores de los campos
    final String username = _usernameController.text;
    final String password = _passwordController.text;

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        //convertir datos a formato JSON
        body: jsonEncode(<String, String>{
          'username': username,
          'password': password,
        }),
      );

      setState(() {
        _isLoading = false; // Detenemos el indicador de carga
      });
      //----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

      //CONDICIONES********************************************************************************************************
      if (response.statusCode == 200) {
        // Login exitoso
        //Convierte la cadena JSON a un Map
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final String accessToken = responseData['access'];
        final String refreshToken = responseData['refresh'];

        // Guardar los tokens de forma segura
        final prefs =
            await SharedPreferences.getInstance(); //Para almacenar datos simples del usuario
        await prefs.setString('accessToken', accessToken);
        await prefs.setString('refreshToken', refreshToken);

        _showMessage(
          'Login exitoso!',
          Colors.green,
        ); //Confirmacion acceso exitoso
        //mostramos en consolaq
        print('Login exitoso. Access Token: $accessToken');
        print('Refresh Token: $refreshToken');

        if (!mounted) return; // Comprobar si el widget sigue en el árbol.
        Navigator.pushReplacementNamed(
          context,
          '/postlogin',
        ); //Pasamos a HomeScreen
      } else if (response.statusCode == 401) {
        // Credenciales inválidas
        _showMessage('Credenciales inválidas. Intenta de nuevo.', Colors.red);
        print('Error de Login (401): ${response.body}'); //consola
      } else {
        // Otros errores del servidor
        _showMessage(
          'Error en el servidor: ${response.statusCode}',
          Colors.red,
        );
        print(
          'Error de Login: ${response.statusCode} - ${response.body}',
        ); //respuesta del servidor en consola
      }
    } catch (e) {
      //exception
      setState(() {
        _isLoading =
            false; // Detenemos el indicador de carga si hay un error de red
      });
      _showMessage('Error de conexión: $e', Colors.red);
      print('Excepción durante el login: $e'); //consola
    }
  }
  //----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

  //FUNCION PARA MOSTRAR MENSAJE EMERGENTE******************************************************************************
  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  //--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

  //WIDGETS************************************************************************************************************
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar Sesión')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, //Llave de formulario
          child: Column(
            children: <Widget>[
              //LOGO************************************************************************************************
              const SizedBox(height: 90),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Image.asset("assets/images/CopiaLogo.PNG"),
              ),
              //USERNAME FIELD***************************************************************************************
              const SizedBox(height: 35),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de Usuario',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa tu nombre de usuario';
                  }
                  return null;
                },
              ),
              //PASSWORD FIELD***************************************************************************************
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa tu contraseña';
                  }
                  return null;
                },
              ),
              //BTN LOGIN********************************************************************************************
              const SizedBox(height: 30),
              _isLoading
                  ? const CircularProgressIndicator() // Muestra un indicador de carga
                  : SizedBox(
                    width: double.infinity, // Ocupa todo el ancho disponible
                    child: ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Iniciar Sesión',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/register',
                  ); // Navegar a la pantalla de registro
                },
                child: const Text('¿No tienes cuenta? Regístrate aquí.'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
