// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/stats_model.dart';
import 'add_vente_screen.dart';
import 'add_depense_screen.dart';
import 'clients_screen.dart';
import 'historique_screen.dart';
import 'stats_screen.dart';
import 'manage_clients_screen.dart';
import 'voice_command_screen.dart';
import 'subscription_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  StatsJour? _stats;
  Map<String, dynamic>? _subscriptionInfo;
  bool _isLoading = true;
  bool _hasSubscriptionAccess = true;

  @override
  void initState() {
    super.initState();
    _checkAccessAndLoadData();
  }

  Future<void> _checkAccessAndLoadData() async {
    setState(() => _isLoading = true);
    
    try {
      // 1. Charger le token d'authentification
      await _apiService.loadToken();
      
      // 2. Vérifier l'accès par souscription
      final accessResult = await _apiService.checkSubscriptionAccess();
      final hasAccess = accessResult['access']['hasAccess'] == true;
      
      setState(() {
        _subscriptionInfo = accessResult['access'];
      });
      
      if (!hasAccess) {
        setState(() {
          _hasSubscriptionAccess = false;
          _isLoading = false;
        });
        return;
      }
      
      // 3. Charger les statistiques si l'accès est autorisé
      final stats = await _apiService.getStatsJour();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      
      // Si erreur d'authentification, rediriger vers login
      if (e.toString().contains('401') || e.toString().contains('token')) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _apiService.getStatsJour();
      setState(() {
        _stats = stats;
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

  String _formatMontant(double montant) {
    final formatter = NumberFormat('#,##0', 'fr_FR');
    return '${formatter.format(montant)} F';
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMMM yyyy à HH:mm', 'fr_FR').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'trial':
        return Colors.blue;
      case 'active':
        return Colors.green;
      case 'expired':
        return Colors.red;
      case 'cancelled':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'trial':
        return 'Essai Gratuit';
      case 'active':
        return 'Abonnement Actif';
      case 'expired':
        return 'Abonnement Expiré';
      case 'cancelled':
        return 'Abonnement Annulé';
      default:
        return status;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'trial':
        return Icons.timer;
      case 'active':
        return Icons.check_circle;
      case 'expired':
        return Icons.warning;
      case 'cancelled':
        return Icons.block;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si pas d'accès à la souscription, afficher l'écran de souscription
    if (!_hasSubscriptionAccess) {
      return const SubscriptionScreen(isTrialExpired: true);
    }
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Mon Commerce',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _apiService.clearToken();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date du jour
                    Text(
                      DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(DateTime.now()),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Carte Information d'abonnement
                    if (_subscriptionInfo != null) _buildSubscriptionCard(),
                    const SizedBox(height: 16),

                    // Carte Bénéfice
                    _buildBeneficeCard(),
                    const SizedBox(height: 16),

                    // Cartes Ventes et Dépenses
                    Row(
                      children: [
                        Expanded(child: _buildVentesCard()),
                        const SizedBox(width: 12),
                        Expanded(child: _buildDepensesCard()),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Boutons d'actions principaux
                    const Text(
                      'Actions rapides',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildActionButtons(),

                    // Bouton commande vocale (ajouté ici au lieu du FloatingActionButton)
                    const SizedBox(height: 24),
                    _buildVoiceCommandButton(),
                    const SizedBox(height: 32), // Espace pour éviter que le bouton ne touche le bas
                  ],
                ),
              ),
            ),
      // FloatingActionButton retiré car maintenant intégré dans le body
    );
  }

  Widget _buildVoiceCommandButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const VoiceCommandScreen()),
          );
          if (result == true) {
            _loadStats(); // Rafraîchir si succès
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          elevation: 4,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          shadowColor: Colors.deepPurple.withOpacity(0.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mic, size: 28),
            const SizedBox(width: 12),
            const Text(
              'Commande Vocale',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard() {
    final status = _subscriptionInfo?['status'] ?? 'unknown';
    final message = _subscriptionInfo?['message'] ?? '';
    final hoursLeft = _subscriptionInfo?['hoursLeft'] ?? 0;
    final expiresAt = _subscriptionInfo?['expiresAt'] ?? '';
    
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);
    final statusIcon = _getStatusIcon(status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  statusIcon,
                  color: statusColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    if (message.isNotEmpty)
                      Text(
                        message,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Heures restantes (pour les essais)
          if (hoursLeft > 0 && status == 'trial')
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: Colors.blue[700],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$hoursLeft heures restantes',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
          
          // Date d'expiration
          if (expiresAt.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Expire le ${_formatDate(expiresAt)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Bouton pour gérer l'abonnement
          if (status == 'trial' || status == 'active')
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SubscriptionScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.upgrade, size: 18),
                  label: const Text('Gérer mon abonnement'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: statusColor,
                    side: BorderSide(color: statusColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBeneficeCard() {
    final benefice = _stats?.benefice ?? 0;
    final isPositive = benefice >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPositive
              ? [Colors.green[400]!, Colors.green[600]!]
              : [Colors.orange[400]!, Colors.orange[600]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isPositive ? Colors.green : Colors.orange).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 8),
              const Text(
                'Bénéfice du jour',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _formatMontant(benefice),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVentesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shopping_cart, color: Colors.green, size: 28),
          const SizedBox(height: 8),
          const Text(
            'Ventes',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatMontant(_stats?.ventes.total ?? 0),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_stats?.ventes.nombre ?? 0} vente(s)',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepensesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.money_off, color: Colors.red, size: 28),
          const SizedBox(height: 8),
          const Text(
            'Dépenses',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatMontant(_stats?.depenses.total ?? 0),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_stats?.depenses.nombre ?? 0} dépense(s)',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.add_shopping_cart,
                label: 'Nouvelle vente',
                color: Colors.green,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddVenteScreen()),
                  );
                  _loadStats();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Icons.remove_circle_outline,
                label: 'Nouvelle dépense',
                color: Colors.orange,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddDepenseScreen()),
                  );
                  _loadStats();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.people,
                label: 'Clients à crédit',
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ClientsScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Icons.history,
                label: 'Historique',
                color: Colors.purple,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoriqueScreen()),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.bar_chart,
                label: 'Statistiques',
                color: Colors.indigo,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StatsScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Icons.group,
                label: 'Gérer clients',
                color: Colors.teal,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ManageClientsScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}