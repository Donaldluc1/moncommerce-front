// lib/screens/stats_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/stats_model.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = true;
  StatsJour? _statsJour;
  Map<String, dynamic>? _statsMois;
  Map<String, dynamic>? _statsCredits;
  
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _loadAllStats();
  }

  Future<void> _loadAllStats() async {
    setState(() => _isLoading = true);
    try {
      await _apiService.loadToken();
      
      // Charger toutes les stats en parallèle
      final results = await Future.wait([
        _apiService.getStatsJour(),
        _loadStatsMois(),
        _loadStatsCredits(),
      ]);
      
      setState(() {
        _statsJour = results[0] as StatsJour;
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

  Future<void> _loadStatsMois() async {
    try {
      final response = await _apiService.getStatsMois(
        annee: _selectedYear,
        mois: _selectedMonth,
      );
      setState(() => _statsMois = response);
    } catch (e) {
      print('Erreur stats mois: $e');
    }
  }

  Future<void> _loadStatsCredits() async {
    try {
      final response = await _apiService.getStatsCredits();
      setState(() => _statsCredits = response);
    } catch (e) {
      print('Erreur stats crédits: $e');
    }
  }

  String _formatMontant(double montant) {
    final formatter = NumberFormat('#,##0', 'fr_FR');
    return '${formatter.format(montant)} F';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques'),
        backgroundColor: Colors.purple,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAllStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats du jour
                    _buildDayStatsCard(),
                    const SizedBox(height: 20),

                    // Sélecteur de mois
                    _buildMonthSelector(),
                    const SizedBox(height: 16),

                    // Stats du mois
                    _buildMonthStatsCard(),
                    const SizedBox(height: 20),

                    // Stats crédits
                    _buildCreditsStatsCard(),
                    const SizedBox(height: 20),

                    // Graphiques (optionnel)
                    _buildQuickInsights(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDayStatsCard() {
    if (_statsJour == null) return const SizedBox();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.today, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  'Aujourd\'hui',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Bénéfice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _statsJour!.benefice >= 0 
                    ? Colors.green[50] 
                    : Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Bénéfice',
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    _formatMontant(_statsJour!.benefice),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _statsJour!.benefice >= 0 
                          ? Colors.green[700] 
                          : Colors.orange[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Ventes
            _buildStatRow(
              'Ventes totales',
              _formatMontant(_statsJour!.ventes.total),
              '${_statsJour!.ventes.nombre} vente(s)',
              Colors.green,
            ),
            const Divider(height: 24),

            // Cash
            _buildStatRow(
              'Cash',
              _formatMontant(_statsJour!.ventes.cash),
              '',
              Colors.blue,
            ),
            const SizedBox(height: 8),

            // Crédit
            _buildStatRow(
              'Crédit',
              _formatMontant(_statsJour!.ventes.credit),
              '',
              Colors.orange,
            ),
            const Divider(height: 24),

            // Dépenses
            _buildStatRow(
              'Dépenses',
              _formatMontant(_statsJour!.depenses.total),
              '${_statsJour!.depenses.nombre} dépense(s)',
              Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    final months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Bouton mois précédent
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                setState(() {
                  if (_selectedMonth == 1) {
                    _selectedMonth = 12;
                    _selectedYear--;
                  } else {
                    _selectedMonth--;
                  }
                });
                _loadStatsMois();
              },
            ),

            // Affichage mois/année
            Text(
              '${months[_selectedMonth - 1]} $_selectedYear',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            // Bouton mois suivant
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                final now = DateTime.now();
                if (_selectedYear < now.year || 
                    (_selectedYear == now.year && _selectedMonth < now.month)) {
                  setState(() {
                    if (_selectedMonth == 12) {
                      _selectedMonth = 1;
                      _selectedYear++;
                    } else {
                      _selectedMonth++;
                    }
                  });
                  _loadStatsMois();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthStatsCard() {
    if (_statsMois == null) return const SizedBox();

    final ventes = _statsMois!['ventes'];
    final depenses = _statsMois!['depenses'];
    final benefice = _statsMois!['benefice'];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_month, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Mois de ${_statsMois!['periode']}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Bénéfice mensuel
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: benefice >= 0
                      ? [Colors.green[400]!, Colors.green[600]!]
                      : [Colors.orange[400]!, Colors.orange[600]!],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Bénéfice du mois',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _formatMontant(benefice.toDouble()),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Ventes mensuelles
            _buildStatRow(
              'Ventes totales',
              _formatMontant(ventes['total'].toDouble()),
              '${ventes['nombre']} vente(s)',
              Colors.green,
            ),
            const SizedBox(height: 8),
            _buildStatRow(
              'Cash',
              _formatMontant(ventes['cash'].toDouble()),
              '',
              Colors.blue,
            ),
            const SizedBox(height: 8),
            _buildStatRow(
              'Crédit',
              _formatMontant(ventes['credit'].toDouble()),
              '',
              Colors.orange,
            ),
            const Divider(height: 24),

            // Dépenses mensuelles
            _buildStatRow(
              'Dépenses',
              _formatMontant(depenses['total'].toDouble()),
              '${depenses['nombre']} dépense(s)',
              Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditsStatsCard() {
    if (_statsCredits == null) return const SizedBox();

    final totalCredits = _statsCredits!['totalCredits'];
    final nombreClients = _statsCredits!['nombreClients'];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Crédits en cours',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total à récupérer',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatMontant(totalCredits.toDouble()),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$nombreClients',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
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

  Widget _buildQuickInsights() {
    if (_statsJour == null || _statsMois == null) return const SizedBox();

    // Calculer quelques insights
    final avgVenteJour = _statsJour!.ventes.nombre > 0
        ? _statsJour!.ventes.total / _statsJour!.ventes.nombre
        : 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.insights, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Aperçu rapide',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildInsightRow(
              'Vente moyenne du jour',
              _formatMontant(avgVenteJour.toDouble()),
              Icons.trending_up,
            ),
            const SizedBox(height: 12),

            _buildInsightRow(
              'Taux de crédit',
              '${(_statsJour!.ventes.total > 0 ? (_statsJour!.ventes.credit / _statsJour!.ventes.total * 100) : 0).toStringAsFixed(1)}%',
              Icons.credit_card,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, String subtitle, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(fontSize: 16)),
              ],
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildInsightRow(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.green[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
        ],
      ),
    );
  }
}