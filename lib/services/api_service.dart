// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/client_model.dart';
import '../models/depense_model.dart';
import '../models/vente_model.dart';
import '../models/stats_model.dart';

class ApiService {
  String? _token;

  // Récupérer le token stocké
  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
  }

  // Sauvegarder le token
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    _token = token;
  }

  // Supprimer le token (déconnexion)
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    _token = null;
  }

  // Headers avec authentification
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // AUTHENTIFICATION

  Future<Map<String, dynamic>> register({
    required String telephone,
    required String password,
    required String nomCommerce,
    String? typeActivite,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.auth}/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'telephone': telephone,
        'password': password,
        'nomCommerce': nomCommerce,
        'typeActivite': typeActivite,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      await saveToken(data['token']);
      return data;
    } else {
      throw Exception(data['error'] ?? 'Erreur lors de l\'inscription');
    }
  }

  Future<Map<String, dynamic>> login({
    required String telephone,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.auth}/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'telephone': telephone,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      await saveToken(data['token']);
      return data;
    } else {
      throw Exception(data['error'] ?? 'Erreur lors de la connexion');
    }
  }

  // VENTES

  Future<Vente> createVente({
    required double montant,
    required String modePaiement,
    String? nomClient,
    String? notes,
    String? clientId,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.ventes),
      headers: _headers,
      body: jsonEncode({
        'montant': montant,
        'modePaiement': modePaiement,
        'nomClient': nomClient,
        'notes': notes,
        'clientId': clientId,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return Vente.fromJson(data['vente']);
    } else {
      throw Exception(data['error'] ?? 'Erreur lors de la création de la vente');
    }
  }

  Future<List<Vente>> getVentes({int limit = 50}) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.ventes}?limit=$limit'),
      headers: _headers,
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return (data['ventes'] as List)
          .map((v) => Vente.fromJson(v))
          .toList();
    } else {
      throw Exception(data['error'] ?? 'Erreur lors de la récupération des ventes');
    }
  }

  // DÉPENSES

  Future<Depense> createDepense({
    required double montant,
    required String motif,
    String? categorie,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.depenses),
      headers: _headers,
      body: jsonEncode({
        'montant': montant,
        'motif': motif,
        'categorie': categorie,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return Depense.fromJson(data['depense']);
    } else {
      throw Exception(data['error'] ?? 'Erreur lors de la création de la dépense');
    }
  }

  Future<List<Depense>> getDepenses({int limit = 50}) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.depenses}?limit=$limit'),
      headers: _headers,
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return (data['depenses'] as List)
          .map((d) => Depense.fromJson(d))
          .toList();
    } else {
      throw Exception(data['error'] ?? 'Erreur lors de la récupération des dépenses');
    }
  }

  // CLIENTS

  Future<Client> createClient({
    required String nom,
    String? telephone,
    String? adresse,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.clients),
      headers: _headers,
      body: jsonEncode({
        'nom': nom,
        'telephone': telephone,
        'adresse': adresse,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return Client.fromJson(data['client']);
    } else {
      throw Exception(data['error'] ?? 'Erreur lors de la création du client');
    }
  }

  Future<List<Client>> getClients({bool avecCredit = false}) async {
    final url = avecCredit
        ? '${ApiConfig.clients}?avecCredit=true'
        : ApiConfig.clients;

    final response = await http.get(
      Uri.parse(url),
      headers: _headers,
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return (data['clients'] as List)
          .map((c) => Client.fromJson(c))
          .toList();
    } else {
      throw Exception(data['error'] ?? 'Erreur lors de la récupération des clients');
    }
  }

  Future<void> createPaiement({
    required String clientId,
    required double montant,
    String? notes,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.clients}/paiements'),
      headers: _headers,
      body: jsonEncode({
        'clientId': clientId,
        'montant': montant,
        'notes': notes,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 201) {
      throw Exception(data['error'] ?? 'Erreur lors de l\'enregistrement du paiement');
    }
  }

  Future<void> deleteClient(String clientId) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.clients}/$clientId'),
      headers: _headers,
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['error'] ?? 'Erreur lors de la suppression du client');
    }
  }

  // STATISTIQUES

  Future<StatsJour> getStatsJour() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.stats}/jour'),
      headers: _headers,
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return StatsJour.fromJson(data);
    } else {
      throw Exception(data['error'] ?? 'Erreur lors de la récupération des statistiques');
    }
  }

  Future<Map<String, dynamic>> getStatsMois({int? annee, int? mois}) async {
    final now = DateTime.now();
    final year = annee ?? now.year;
    final month = mois ?? now.month;

    final response = await http.get(
      Uri.parse('${ApiConfig.stats}/mois?annee=$year&mois=$month'),
      headers: _headers,
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Erreur lors de la récupération des statistiques');
    }
  }

  Future<Map<String, dynamic>> getStatsCredits() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.stats}/credits'),
      headers: _headers,
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Erreur lors de la récupération des statistiques');
    }
  }

  Future<Map<String, dynamic>> getResume() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.stats}/resume'),
      headers: _headers,
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Erreur lors de la récupération du résumé');
    }
  }

  // IA - COMMANDE VOCALE

  Future<Map<String, dynamic>> sendVoiceCommand(String text) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/ai/voice-command'),
      headers: _headers,
      body: jsonEncode({
        'text': text,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Erreur lors du traitement de la commande');
    }
  }

  // SUBSCRIPTION / ABONNEMENT

  Future<Map<String, dynamic>> checkSubscriptionAccess() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/subscription/check'),
      headers: _headers,
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Erreur lors de la vérification');
    }
  }

  Future<Map<String, dynamic>> getSubscriptionInfo() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/subscription/info'),
      headers: _headers,
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data['data'];
    } else {
      throw Exception(data['error'] ?? 'Erreur lors de la récupération des infos');
    }
  }

  Future<Map<String, dynamic>> activateSubscription({
    required String plan,
    required String paymentMethod,
    required String phoneNumber,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/subscription/activate'),
      headers: _headers,
      body: jsonEncode({
        'plan': plan,
        'paymentMethod': paymentMethod,
        'phoneNumber': phoneNumber,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Erreur lors de l\'activation');
    }
  }
}