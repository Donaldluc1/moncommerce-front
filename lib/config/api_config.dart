// lib/config/api_config.dart
class ApiConfig {
  // À MODIFIER : URL de votre API déployée
  static const String baseUrl = 'http://147.93.95.216:3002/api';
  
  // En production, utiliser :
  //static const String baseUrl = 'https://moncommerce-production.up.railway.app/api';
  
  // Endpoints
  static const String auth = '$baseUrl/auth';
  static const String ventes = '$baseUrl/ventes';
  static const String depenses = '$baseUrl/depenses';
  static const String clients = '$baseUrl/clients';
  static const String stats = '$baseUrl/stats';
  
  // Timeout
  static const Duration timeout = Duration(seconds: 30);
}