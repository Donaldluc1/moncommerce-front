// lib/screens/payment_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class PaymentScreen extends StatefulWidget {
  final String plan;
  final String planName;
  final int amount;

  const PaymentScreen({
    super.key,
    required this.plan,
    required this.planName,
    required this.amount,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final ApiService _apiService = ApiService();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  String _selectedMethod = 'orange_money';
  bool _isProcessing = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String _formatAmount(int amount) {
    final formatter = NumberFormat('#,##0', 'fr_FR');
    return '${formatter.format(amount)} F';
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      await _apiService.loadToken();
      
      // Appeler l'API d'activation
      final result = await _apiService.activateSubscription(
        plan: widget.plan,
        paymentMethod: _selectedMethod,
        phoneNumber: _phoneController.text.trim(),
      );

      if (mounted) {
        setState(() => _isProcessing = false);
        
        // Afficher dialog de succès
        _showSuccessDialog(result['transactionId']);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showSuccessDialog(String transactionId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icône de succès
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 60,
              ),
            ),
            const SizedBox(height: 24),

            // Titre
            const Text(
              'Paiement réussi !',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              'Votre abonnement ${widget.planName} a été activé avec succès.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Transaction ID
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    'Transaction',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    transactionId,
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fermer dialog
                Navigator.of(context).pop(true); // Retour avec succès
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continuer',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Récapitulatif de la commande
              _buildOrderSummary(),
              const SizedBox(height: 32),

              // Méthode de paiement
              const Text(
                'Méthode de paiement',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              _buildPaymentMethod(
                'orange_money',
                'Orange Money',
                '🟠',
                Colors.orange,
              ),
              const SizedBox(height: 12),

              _buildPaymentMethod(
                'mtn_money',
                'MTN Mobile Money',
                '🟡',
                Colors.amber,
              ),
              const SizedBox(height: 12),

              _buildPaymentMethod(
                'moov_money',
                'Moov Money',
                '🔵',
                Colors.blue,
              ),
              const SizedBox(height: 12),

              _buildPaymentMethod(
                'wave',
                'Wave',
                '💙',
                Colors.lightBlue,
              ),

              const SizedBox(height: 32),

              // Numéro de téléphone
              const Text(
                'Numéro de téléphone',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: '0708090102',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez entrer votre numéro';
                  }
                  if (value.trim().length < 10) {
                    return 'Numéro invalide';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Bouton payer
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    disabledBackgroundColor: Colors.grey[400],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.payment, color: Colors.white),
                            const SizedBox(width: 12),
                            Text(
                              'Payer ${_formatAmount(widget.amount)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Note sécurité
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock, size: 18, color: Colors.green[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Paiement 100% sécurisé via Mobile Money',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Informations complémentaires
              _buildInfoCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple[50]!, Colors.deepPurple[100]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shopping_cart, color: Colors.deepPurple),
                const SizedBox(width: 8),
                const Text(
                  'Récapitulatif',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            
            _buildSummaryRow('Forfait', widget.planName),
            const SizedBox(height: 8),
            _buildSummaryRow('Durée', _getDuration()),
            const SizedBox(height: 8),
            _buildSummaryRow('Montant', _formatAmount(widget.amount)),
            
            const Divider(height: 24),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total à payer',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatAmount(widget.amount),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _getDuration() {
    switch (widget.plan) {
      case 'monthly':
        return '1 mois';
      case 'quarterly':
        return '3 mois';
      case 'semesterly':
        return '6 mois';
      case 'yearly':
        return '1 an';
      default:
        return '';
    }
  }

  Widget _buildPaymentMethod(String value, String label, String emoji, Color color) {
    final isSelected = _selectedMethod == value;

    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? color : Colors.grey,
                  width: 2,
                ),
                color: isSelected ? color : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : Colors.black,
                ),
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Sélectionné',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Colors.blue[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Informations',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoItem('• Votre abonnement sera activé immédiatement'),
            _buildInfoItem('• Aucun engagement, vous pouvez annuler à tout moment'),
            _buildInfoItem('• Support client disponible 7j/7'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: Colors.blue[900],
          height: 1.4,
        ),
      ),
    );
  }
}