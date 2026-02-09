// lib/screens/subscription_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'payment_screen.dart';

class SubscriptionScreen extends StatefulWidget {
  final bool isTrialExpired;
  
  const SubscriptionScreen({
    super.key,
    this.isTrialExpired = false,
  });

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = true;
  Map<String, dynamic>? _subscriptionInfo;
  String? _selectedPlan;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionInfo();
  }

  Future<void> _loadSubscriptionInfo() async {
    setState(() => _isLoading = true);
    try {
      await _apiService.loadToken();
      final info = await _apiService.getSubscriptionInfo();
      setState(() {
        _subscriptionInfo = info;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatAmount(dynamic amount) {
    final formatter = NumberFormat('#,##0', 'fr_FR');
    return '${formatter.format(amount)} F';
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !widget.isTrialExpired,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Abonnement'),
          backgroundColor: Colors.deepPurple,
          automaticallyImplyLeading: !widget.isTrialExpired,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Statut actuel
                    _buildCurrentStatus(),
                    const SizedBox(height: 32),

                    // Titre
                    const Text(
                      'Choisissez votre forfait',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Accédez à toutes les fonctionnalités',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Plans
                    _buildPlanCard(
                      'monthly',
                      'Mensuel',
                      2000,
                      '1 mois',
                      savings: null,
                    ),
                    const SizedBox(height: 16),

                    _buildPlanCard(
                      'quarterly',
                      'Trimestriel',
                      5000,
                      '3 mois',
                      savings: 1000,
                      badge: 'Économisez 1,000 F',
                    ),
                    const SizedBox(height: 16),

                    _buildPlanCard(
                      'semesterly',
                      'Semestriel',
                      10000,
                      '6 mois',
                      savings: 2000,
                      badge: 'Économisez 2,000 F',
                    ),
                    const SizedBox(height: 16),

                    _buildPlanCard(
                      'yearly',
                      'Annuel',
                      20000,
                      '1 an',
                      savings: 4000,
                      badge: '⭐ Meilleure offre',
                      popular: true,
                    ),
                    
                    const SizedBox(height: 32),

                    // Bouton continuer
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _selectedPlan == null ? null : _proceedToPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          disabledBackgroundColor: Colors.grey[300],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _selectedPlan == null
                              ? 'Sélectionnez un plan'
                              : 'Continuer',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCurrentStatus() {
    if (_subscriptionInfo == null) return const SizedBox();

    final access = _subscriptionInfo!['access'];
    final status = access['status'];

    if (status == 'trial') {
      final hoursLeft = access['hoursLeft'] ?? 0;
      return Card(
        color: Colors.blue[50],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.access_time, color: Colors.blue, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Essai gratuit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$hoursLeft heure(s) restante(s)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else if (status == 'active') {
      final daysLeft = access['daysLeft'] ?? 0;
      final planName = access['planName'] ?? '';
      return Card(
        color: Colors.green[50],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Abonnement $planName actif',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$daysLeft jour(s) restant(s)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Expiré
    return Card(
      color: Colors.red[50],
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 32),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Abonnement expiré',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Choisissez un plan pour continuer',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    String planId,
    String name,
    int amount,
    String duration, {
    int? savings,
    String? badge,
    bool popular = false,
  }) {
    final isSelected = _selectedPlan == planId;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = planId),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple[50] : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.deepPurple : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (popular)
              BoxShadow(
                color: Colors.deepPurple.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Radio
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.deepPurple : Colors.grey,
                        width: 2,
                      ),
                      color: isSelected ? Colors.deepPurple : Colors.transparent,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 16),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          duration,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (savings != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Économisez ${_formatAmount(savings)}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Prix
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatAmount(amount),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.deepPurple : Colors.black,
                        ),
                      ),
                      if (savings != null)
                        Text(
                          '${(amount / (duration == '3 mois' ? 3 : duration == '6 mois' ? 6 : 12)).toStringAsFixed(0)} F/mois',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Badge
            if (badge != null)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: popular ? Colors.amber : Colors.green,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(14),
                      bottomLeft: Radius.circular(14),
                    ),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _proceedToPayment() {
    if (_selectedPlan == null) return;

    final plans = {
      'monthly': {'name': 'Mensuel', 'amount': 2000},
      'quarterly': {'name': 'Trimestriel', 'amount': 5000},
      'semesterly': {'name': 'Semestriel', 'amount': 10000},
      'yearly': {'name': 'Annuel', 'amount': 20000},
    };

    final planInfo = plans[_selectedPlan];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          plan: _selectedPlan!,
          planName: planInfo!['name'] as String,
          amount: planInfo['amount'] as int,
        ),
      ),
    ).then((success) {
      if (success == true) {
        // Paiement réussi → retour à l'accueil
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
  }
}