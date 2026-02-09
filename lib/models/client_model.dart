
// lib/models/client_model.dart
class Client {
  final String id;
  final String nom;
  final String? telephone;
  final String? adresse;
  final double totalCredit;

  Client({
    required this.id,
    required this.nom,
    this.telephone,
    this.adresse,
    required this.totalCredit,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'],
      nom: json['nom'],
      telephone: json['telephone'],
      adresse: json['adresse'],
      totalCredit: (json['totalCredit'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'telephone': telephone,
      'adresse': adresse,
    };
  }
}
