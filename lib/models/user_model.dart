// lib/models/user_model.dart
class User {
  final String id;
  final String telephone;
  final String? email;
  final String nomCommerce;
  final String? typeActivite;

  User({
    required this.id,
    required this.telephone,
    this.email,
    required this.nomCommerce,
    this.typeActivite,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      telephone: json['telephone'],
      email: json['email'],
      nomCommerce: json['nomCommerce'],
      typeActivite: json['typeActivite'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'telephone': telephone,
      'email': email,
      'nomCommerce': nomCommerce,
      'typeActivite': typeActivite,
    };
  }
}
