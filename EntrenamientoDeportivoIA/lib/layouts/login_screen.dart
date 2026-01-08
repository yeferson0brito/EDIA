//IMPORTACIONES******************************************************************************************************
// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
// Necesitaremos el paquete HTTP para la comunicación con el backend
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
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

        // Decodificar token y extraer grupos/rol (tu serializer añade 'group')
        final Map<String, dynamic> decodedToken = JwtDecoder.decode(accessToken);
        print('decodedToken: ${jsonEncode(decodedToken)}'); // depuración

        String? userRole;
        //  claim 'group' desde el token 
        if (decodedToken.containsKey('group')) {
          final groupsClaim = decodedToken['group'];
          if (groupsClaim is List && groupsClaim.isNotEmpty) {
            userRole = groupsClaim.first?.toString();
          } else if (groupsClaim is String) {
            userRole = groupsClaim;
          }
        }
        // fallback: respuesta del login incluye user -> groups
        if (userRole == null && responseData.containsKey('user')) {
          final userObj = responseData['user'];
          if (userObj is Map && userObj.containsKey('groups')) {
            final groupsResp = userObj['groups'];
            if (groupsResp is List && groupsResp.isNotEmpty) {
              userRole = groupsResp.first?.toString();
            } else if (groupsResp is String) {
              userRole = groupsResp;
            }
          }
        }
//##############################################################################
// valor por defecto si no hay información
        userRole ??= 'Usuario Básico';

        // VERIFICAR ONBOARDING
        // Intentamos obtener el estado 'onboarded' de la respuesta.
        // Asumimos que la respuesta JSON tiene una estructura donde podemos encontrarlo.
        // Si no viene en el login, por defecto lo mandamos al onboarding para asegurar los datos.
        bool isOnboarded = false;
        
        // Verificamos directamente en 'user' -> 'onboarded' según tu estructura JSON
        if (responseData.containsKey('user') && responseData['user'] is Map<String, dynamic>) {
           final userMap = responseData['user'];
           // Usamos el operador ?? false para asegurar que sea booleano
           isOnboarded = userMap['onboarded'] ?? false;
           print('Estado Onboarding detectado: $isOnboarded');
        }

//###################################################################################################################################
        // Guardar los tokens
        final prefs =
            await SharedPreferences.getInstance(); //Para almacenar datos simples del usuario
        await prefs.setString('accessToken', accessToken);
        await prefs.setString('refreshToken', refreshToken);
        await prefs.setString('rolUser', userRole);
        print('Rol del usuario: $userRole');

        _showMessage('Login exitoso!', Colors.green); //Confirmacion acceso
        print('Login exitoso. Access Token: $accessToken');
        print('Refresh Token: $refreshToken');
        print('Rol del usuario: $userRole');
        print('RESPONSE BODY  ${response.body}');

        if (!mounted) return; // Comprobar si el widget sigue en el árbol.

//###################################################################################################################################
        
        // REDIRECCIÓN INTELIGENTE
        // Si ya hizo onboarding -> Home. Si no -> OnboardingScreen
        final String nextRoute = isOnboarded ? '/home' : '/onboarding';

        Navigator.pushReplacementNamed(
          context,
          nextRoute,///home
        ); //Pasamos a HomeScreen
//####################################################################################################################################
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
                child: Image.asset("assets/images/EDIA_Text.png"),
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
