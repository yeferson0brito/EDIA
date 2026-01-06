// lib/models/user_profile.dart

class UserProfile {
  final String? username;
  final String? email;
  final String? dateOfBirth;
  final double? heightCm;
  final double? weightKg;
  final String? gender;
  final bool onboarded;
  final int? role;

  UserProfile({
    this.username,
    this.email,
    this.dateOfBirth,
    this.heightCm,
    this.weightKg,
    this.gender,
    this.onboarded = false,
    this.role,
  });

  /// Crea un UserProfile desde un JSON del backend
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      username: json['username'],
      email: json['email'],
      dateOfBirth: json['date_of_birth'],
      heightCm: _toDouble(json['height_cm']),
      weightKg: _toDouble(json['weight_kg']),
      gender: json['gender'],
      onboarded: json['onboarded'] ?? false,
      role: json['role'],
    );
  }

  /// Convierte el UserProfile a JSON para enviar al backend
  Map<String, dynamic> toJson() {
    return {
      if (username != null) 'username': username,
      if (email != null) 'email': email,
      if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
      if (heightCm != null) 'height_cm': heightCm,
      if (weightKg != null) 'weight_kg': weightKg,
      if (gender != null) 'gender': gender,
      'onboarded': onboarded,
      if (role != null) 'role': role,
    };
  }

  /// Crea una copia del perfil con valores actualizados
  UserProfile copyWith({
    String? username,
    String? email,
    String? dateOfBirth,
    double? heightCm,
    double? weightKg,
    String? gender,
    bool? onboarded,
    int? role,
  }) {
    return UserProfile(
      username: username ?? this.username,
      email: email ?? this.email,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      gender: gender ?? this.gender,
      onboarded: onboarded ?? this.onboarded,
      role: role ?? this.role,
    );
  }

  /// Validar que todos los campos requeridos para onboarding estén presentes
  bool isOnboardingValid() {
    return dateOfBirth != null &&
        dateOfBirth!.isNotEmpty &&
        heightCm != null &&
        heightCm! > 0 &&
        weightKg != null &&
        weightKg! > 0 &&
        gender != null &&
        gender!.isNotEmpty;
  }

  @override
  String toString() {
    return 'UserProfile(username: $username, email: $email, dateOfBirth: $dateOfBirth, heightCm: $heightCm, weightKg: $weightKg, gender: $gender, onboarded: $onboarded, role: $role)';
  }
}

/// Función auxiliar para convertir valores a double
double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    try {
      return double.parse(value);
    } catch (e) {
      return null;
    }
  }
  return null;
}
