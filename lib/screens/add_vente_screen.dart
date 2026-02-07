// lib/screens/add_vente_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../models/client_model.dart';
import '../widgets/client_selector.dart';

class AddVenteScreen extends StatefulWidget {
  const AddVenteScreen({super.key});

  @override
  State<AddVenteScreen> createState() => _AddVenteScreenState();
}

class _AddVenteScreenState extends State<AddVenteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montantController = TextEditingController();
  final ApiService _apiService = ApiService();

  String _modePaiement = 'cash';
  Client? _selectedClient;
  bool _isLoading = false;

  @override
  void dispose() {
    _montantController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    // Si crédit, vérifier qu'un client est sélectionné
    if (_modePaiement == 'credit' && _selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un client pour une vente à crédit'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _apiService.loadToken();
      await _apiService.createVente(
        montant: double.parse(_montantController.text),
        modePaiement: _modePaiement,
        nomClient: _selectedClient?.nom,
        clientId: _modePaiement == 'credit' ? _selectedClient?.id : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vente enregistrée !'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle vente'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Montant (GROS)
              const Text(
                'Montant de la vente',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _montantController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: '0',
                  suffixText: 'F',
                  suffixStyle: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.green[50],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Entrez le montant';
                  }
                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                    return 'Montant invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Mode de paiement
              const Text(
                'Mode de paiement',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ModeButton(
                      icon: Icons.payments,
                      label: 'Espèces',
                      isSelected: _modePaiement == 'cash',
                      onTap: () => setState(() => _modePaiement = 'cash'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ModeButton(
                      icon: Icons.credit_card,
                      label: 'Crédit',
                      isSelected: _modePaiement == 'credit',
                      onTap: () => setState(() => _modePaiement = 'credit'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Sélecteur de client
              ClientSelector(
                selectedClient: _selectedClient,
                onClientSelected: (client) {
                  setState(() => _selectedClient = client);
                },
                allowCredit: _modePaiement == 'credit',
              ),
              
              if (_modePaiement == 'credit' && _selectedClient == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '* Obligatoire pour une vente à crédit',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              
              const SizedBox(height: 40),

              // Bouton Enregistrer
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Enregistrer la vente',
                          style: TextStyle(
                            fontSize: 20,
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
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 36,
              color: isSelected ? Colors.white : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}