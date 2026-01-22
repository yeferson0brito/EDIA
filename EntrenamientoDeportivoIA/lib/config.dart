class DireccionBaseURL {
  // CAMBIA ESTA IP por tu IPv4 real (ej: 192.168.1.15)
  // Usa 'ipconfig' en la terminal para ver tu "Dirección IPv4"
  static const String _baseUrl = "http://192.168.18.173:8000"; 

  static const String loginUrl = "$_baseUrl/api/login/";
  static const String registerUrl = "$_baseUrl/api/register/";
  static const String onboardingUrl = "$_baseUrl/api/onboarding/";
}