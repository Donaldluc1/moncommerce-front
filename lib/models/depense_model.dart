
// lib/models/depense_model.dart
class Depense {
  final String id;
  final double montant;
  final String motif;
  final DateTime date;
  final String? categorie;

  Depense({
    required this.id,
    required this.montant,
    required this.motif,
    required this.date,
    this.categorie,
  });

  factory Depense.fromJson(Map<String, dynamic> json) {
    return Depense(
      id: json['id'],
      montant: (json['montant'] as num).toDouble(),
      motif: json['motif'],
      date: DateTime.parse(json['date']),
      categorie: json['categorie'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'montant': montant,
      'motif': motif,
      'categorie': categorie,
    };
  }
}
