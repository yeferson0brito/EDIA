// lib/services/api_service.dart

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_profile.dart';

class ApiService {
  static const String baseUrl = "http://10.0.2.2:8000/api";

  // Headers comunes para las solicitudes
  static Future<Map<String, String>> _getHeaders({bool requiresAuth = false}) async {
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
    };

    if (requiresAuth) {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');
      if (accessToken != null) {
        headers['Authorization'] = 'Bearer $accessToken';
      }
    }

    return headers;
  }

  /// Enviar datos de onboarding al backend
  /// Requiere token de acceso
  static Future<ApiResponse<UserProfile>> submitOnboarding({
    required String dateOfBirth,
    required double height,
    required double weight,
    required String gender,
  }) async {
    try {
      final headers = await _getHeaders(requiresAuth: true);

      final body = {
        'date_of_birth': dateOfBirth,
        'height_cm': height,
        'weight_kg': weight,
        'gender': gender,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/users/onboarding/'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final userProfile = UserProfile.fromJson(data);
        return ApiResponse.success(userProfile);
      } else if (response.statusCode == 400) {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        final errorMessage = _parseErrorMessage(errorData);
        return ApiResponse.error(errorMessage);
      } else if (response.statusCode == 401) {
        return ApiResponse.error('Tu sesión ha expirado. Por favor, inicia sesión de nuevo.');
      } else {
        return ApiResponse.error('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  /// Obtener datos del perfil del usuario
  /// Requiere token de acceso
  static Future<ApiResponse<UserProfile>> getUserProfile() async {
    try {
      final headers = await _getHeaders(requiresAuth: true);

      final response = await http.get(
        Uri.parse('$baseUrl/users/onboarding/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final userProfile = UserProfile.fromJson(data);
        return ApiResponse.success(userProfile);
      } else if (response.statusCode == 401) {
        return ApiResponse.error('Tu sesión ha expirado. Por favor, inicia sesión de nuevo.');
      } else {
        return ApiResponse.error('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  /// Parsear mensaje de error del backend
  static String _parseErrorMessage(Map<String, dynamic> errorData) {
    final StringBuffer message = StringBuffer();
    errorData.forEach((key, value) {
      if (value is List) {
        message.write('$key: ${value.join(", ")}. ');
      } else {
        message.write('$key: $value. ');
      }
    });
    return message.toString().isEmpty ? 'Error desconocido' : message.toString();
  }
}

/// Clase genérica para manejar respuestas de API
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;

  ApiResponse({
    required this.success,
    this.data,
    this.error,
  });

  factory ApiResponse.success(T data) {
    return ApiResponse(
      success: true,
      data: data,
    );
  }

  factory ApiResponse.error(String error) {
    return ApiResponse(
      success: false,
      error: error,
    );
  }
}
