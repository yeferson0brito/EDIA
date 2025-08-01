//IMPORTACIONES******************************************************************************************************
// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; //Para las peticiones POST al servidor BacKend
import 'dart:convert'; //Para convertir las peticiones de formato JSON 
//IMPORTACIONES-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//LLAMADA***********************************************************************************************************
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}
//LLAMADA-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

class _RegisterScreenState extends State<RegisterScreen> {
  //CONTROLADORES PARA CADA CAMPO************************************************************************************
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _password2Controller = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); //Clave/Identificador
  bool _isLoading = false; //Indicador de carga
  // URL de la API de registro en Django
  final String _apiUrl = "http://10.0.2.2:8000/api/register/";
  //FIN CONTROLADORES DE CAMPO ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

  //FUNCION PARA VALIDAR DATOS DEL FORMULARIO***********************************************************************************************************
  //Funcion asíncrona para un proceso que tomara tiempo
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      //Valida el estado de cada campo evitando enviar datos incorrectos/incompletos
      return;
    }

    setState(() {
      //Cambia el estado del indicador de carga
      _isLoading = true;
    });
    //----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    //ENVIO DE DATOS AL SERVIDOR*************************************************************************************************************
    //Obtenemos el texto que contiene cada campo
    final String username = _usernameController.text;
    final String email = _emailController.text;
    final String password = _passwordController.text;
    final String password2 = _password2Controller.text;
    final String firstName = _firstNameController.text;
    final String lastName = _lastNameController.text;

    //Llamado de la api
    try {
      final response = await http.post(
        //Pausar y esperar la respuesta del servidor
        Uri.parse(
          _apiUrl,
        ), //Se convierte el String de la URL a formato URI para http
        //La peticion sera en formato JSON
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        //Datos a enviar jsonEncode transforma el diccionario a formato JSON
        body: jsonEncode(<String, String>{
          'username': username,
          'email': email,
          'password': password,
          'password2': password2,
          'first_name': firstName,
          'last_name': lastName,
        }),
      );

      setState(() {
        _isLoading = false;
      });
      //----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

      //CONDICIONES PARA EL ENVIO DE DATOS*****************************************************************************************
      if (response.statusCode == 201) {
        _showMessage(
          'Registro exitoso! Ahora puedes iniciar sesión.',
          Colors.green,
        );
        // Para limpiar los campos (aunque si el registro es exitoso deberia regresar al login_screen)
        _usernameController.clear();
        _emailController.clear();
        _passwordController.clear();
        _password2Controller.clear();
        _firstNameController.clear();
        _lastNameController.clear();
        Navigator.pop(context); // Regresar a la pantalla anterior (login)
      } else {
        // Error en el registro
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        String errorMessage = 'Error al registrar. Verifica tus datos.';
        //Errores respectivos de cada campo
        if (errorData.containsKey('username')) {
          errorMessage += '\nUsername: ${errorData['username'][0]}';
        }
        if (errorData.containsKey('email')) {
          errorMessage += '\nEmail: ${errorData['email'][0]}';
        }
        if (errorData.containsKey('password')) {
          errorMessage += '\nContraseña: ${errorData['password'][0]}';
        }
        if (errorData.containsKey('non_field_errors')) {
          // Errores de validación a nivel de objeto - No estan asociados a campos especificos
          errorMessage += '\n${errorData['non_field_errors'][0]}';
        }

        _showMessage(errorMessage, Colors.red);
        print('Error de Registro: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      //Excepcion
      setState(() {
        _isLoading = false;
      });
      _showMessage('Error de conexión: $e', Colors.red);
      print('Excepción durante el registro: $e');
    }
  }

  //----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

  //FUNCIÓN PARA MOSTRAR MENSAJES EMERGENTES***************************************************************************
  void _showMessage(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      //Mensaje en la parte de abajo de la pantalla
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  //----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//WIDGETS************************************************************************************************************
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('REGISTRO')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                //LOGO
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Image.asset("assets/images/CopiaLogo.PNG"),
                ),
                //USERNAME FIELD*************************************************************************************
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de usuario',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Campo requerido';
                    }
                    return null;
                  },
                ),
                //EMAIL FIELD****************************************************************************************
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Campo requerido';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Ingresa un email válido';
                    }
                    return null;
                  },
                ),
                //PASSWORD FIELD*************************************************************************************
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
                      return 'Campo requerido';
                    }
                    if (value.length < 8) {
                      return 'La contraseña debe tener al menos 8 caracteres';
                    }
                    return null;
                  },
                ),
                //CONFIRM PASSWORD FIELD************************************************************************************************
                const SizedBox(height: 20),
                TextFormField(
                  controller: _password2Controller,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar Contraseña',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Campo requerido';
                    }
                    if (value != _passwordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),
                //FIRST NAME FIELD***********************************************************************************
                const SizedBox(height: 20),
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre (Opcional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge),
                  ),
                ),
                //LAST NAME FIELD************************************************************************************
                const SizedBox(height: 20),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Apellido (Opcional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge),
                  ),
                ),
                //BTN REGISTRAR*************************************************************************************♂
                const SizedBox(height: 30),
                _isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(                          
                          backgroundColor: Colors.blue, 
                          foregroundColor: Colors.white, 
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Registrarse',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Regresar a la pantalla de login
                  },
                  child: const Text('¿Ya tienes cuenta? Inicia sesión.'),
                ),

                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/postlogin',
                    ); // Regresar a la pantalla de login
                  },
                  child: const Text('||||||||||||||||||'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
