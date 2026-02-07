// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  // Initialiser : vérifier si token existe
  Future<void> initialize() async {
    await _apiService.loadToken();
    // Ici on pourrait charger le profil utilisateur
    // Pour simplifier le MVP, on charge depuis le cache local
    await _loadUserFromCache();
  }

  // Charger user depuis cache
  Future<void> _loadUserFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      // Simuler chargement user
      // Dans une vraie app, parser le JSON
    }
  }

  // Sauvegarder user dans cache
  Future<void> _saveUserToCache(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', user.id);
    await prefs.setString('user_nom', user.nomCommerce);
  }

  // Inscription
  Future<bool> register({
    required String telephone,
    required String password,
    required String nomCommerce,
    String? typeActivite,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.register(
        telephone: telephone,
        password: password,
        nomCommerce: nomCommerce,
        typeActivite: typeActivite,
      );

      _user = User.fromJson(response['user']);
      await _saveUserToCache(_user!);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Connexion
  Future<bool> login({
    required String telephone,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.login(
        telephone: telephone,
        password: password,
      );

      _user = User.fromJson(response['user']);
      await _saveUserToCache(_user!);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Déconnexion
  Future<void> logout() async {
    await _apiService.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _user = null;
    notifyListeners();
  }
}