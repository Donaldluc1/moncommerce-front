
// lib/models/stats_model.dart
class StatsJour {
  final String date;
  final VentesStats ventes;
  final DepensesStats depenses;
  final double benefice;

  StatsJour({
    required this.date,
    required this.ventes,
    required this.depenses,
    required this.benefice,
  });

  factory StatsJour.fromJson(Map<String, dynamic> json) {
    return StatsJour(
      date: json['date'],
      ventes: VentesStats.fromJson(json['ventes']),
      depenses: DepensesStats.fromJson(json['depenses']),
      benefice: (json['benefice'] as num).toDouble(),
    );
  }
}

class VentesStats {
  final double total;
  final double cash;
  final double credit;
  final int nombre;

  VentesStats({
    required this.total,
    required this.cash,
    required this.credit,
    required this.nombre,
  });

  factory VentesStats.fromJson(Map<String, dynamic> json) {
    return VentesStats(
      total: (json['total'] as num).toDouble(),
      cash: (json['cash'] as num).toDouble(),
      credit: (json['credit'] as num).toDouble(),
      nombre: json['nombre'],
    );
  }
}

class DepensesStats {
  final double total;
  final int nombre;

  DepensesStats({
    required this.total,
    required this.nombre,
  });

  factory DepensesStats.fromJson(Map<String, dynamic> json) {
    return DepensesStats(
      total: (json['total'] as num).toDouble(),
      nombre: json['nombre'],
    );
  }
}