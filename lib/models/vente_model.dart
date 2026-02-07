// lib/models/vente_model.dart
class Vente {
  final String id;
  final double montant;
  final String modePaiement;
  final String? nomClient;
  final DateTime date;
  final String? notes;

  Vente({
    required this.id,
    required this.montant,
    required this.modePaiement,
    this.nomClient,
    required this.date,
    this.notes,
  });

  factory Vente.fromJson(Map<String, dynamic> json) {
    return Vente(
      id: json['id'],
      montant: (json['montant'] as num).toDouble(),
      modePaiement: json['modePaiement'],
      nomClient: json['nomClient'],
      date: DateTime.parse(json['date']),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'montant': montant,
      'modePaiement': modePaiement,
      'nomClient': nomClient,
      'notes': notes,
    };
  }
}
