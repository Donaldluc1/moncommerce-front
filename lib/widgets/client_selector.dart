// lib/widgets/client_selector.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/client_model.dart';

class ClientSelector extends StatefulWidget {
  final Client? selectedClient;
  final ValueChanged<Client?> onClientSelected;
  final bool allowCredit;

  const ClientSelector({
    super.key,
    this.selectedClient, 
    required this.onClientSelected,
    this.allowCredit = false,
  });

  @override
  State<ClientSelector> createState() => _ClientSelectorState();
}

class _ClientSelectorState extends State<ClientSelector> {
  final ApiService _apiService = ApiService();
  List<Client> _clients = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    setState(() => _isLoading = true);
    try {
      await _apiService.loadToken();
      final clients = await _apiService.getClients(avecCredit: false);
      setState(() {
        _clients = clients;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Client',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        InkWell(
          onTap: () => _showClientPicker(context),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.person,
                  color: widget.selectedClient != null
                      ? Colors.green
                      : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.selectedClient?.nom ?? 'Sélectionner un client',
                    style: TextStyle(
                      fontSize: 16,
                      color: widget.selectedClient != null
                          ? Colors.black
                          : Colors.grey[600],
                    ),
                  ),
                ),
                if (widget.selectedClient != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () => widget.onClientSelected(null),
                  )
                else
                  const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ),

        if (widget.selectedClient != null && widget.selectedClient!.totalCredit > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, size: 16, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Crédit en cours : ${widget.selectedClient!.totalCredit.toStringAsFixed(0)} F',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _showClientPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ClientPickerSheet(
        clients: _clients,
        selectedClient: widget.selectedClient,
        onClientSelected: (client) {
          widget.onClientSelected(client);
          Navigator.pop(context);
        },
        onCreateClient: () async {
          Navigator.pop(context);
          final newClient = await _showCreateClientDialog(context);
          if (newClient != null) {
            widget.onClientSelected(newClient);
            _loadClients();
          }
        },
      ),
    );
  }

  Future<Client?> _showCreateClientDialog(BuildContext context) async {
    final nomController = TextEditingController();
    final telephoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<Client>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouveau client'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom du client *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom est obligatoire';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: telephoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  final client = await _apiService.createClient(
                    nom: nomController.text.trim(),
                    telephone: telephoneController.text.trim().isEmpty
                        ? null
                        : telephoneController.text.trim(),
                  );
                  if (context.mounted) {
                    Navigator.pop(context, client);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Créer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class ClientPickerSheet extends StatefulWidget {
  final List<Client> clients;
  final Client? selectedClient;
  final ValueChanged<Client> onClientSelected;
  final VoidCallback onCreateClient;

  const ClientPickerSheet({
    super.key,
    required this.clients,
    this.selectedClient,
    required this.onClientSelected,
    required this.onCreateClient,
  });

  @override
  State<ClientPickerSheet> createState() => _ClientPickerSheetState();
}

class _ClientPickerSheetState extends State<ClientPickerSheet> {
  String _searchQuery = '';
  List<Client> _filteredClients = [];

  @override
  void initState() {
    super.initState();
    _filteredClients = widget.clients;
  }

  void _filterClients(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredClients = widget.clients;
      } else {
        _filteredClients = widget.clients.where((client) {
          return client.nom.toLowerCase().contains(_searchQuery) ||
              (client.telephone?.toLowerCase().contains(_searchQuery) ?? false);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Titre
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sélectionner un client',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: widget.onCreateClient,
                icon: const Icon(Icons.add),
                label: const Text('Nouveau'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Champ de recherche
          TextField(
            onChanged: _filterClients,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Rechercher un client...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
          const SizedBox(height: 16),

          // Liste des clients
          Expanded(
            child: _filteredClients.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 60,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Aucun client\nCréez-en un nouveau'
                              : 'Aucun résultat',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredClients.length,
                    itemBuilder: (context, index) {
                      final client = _filteredClients[index];
                      final isSelected = client.id == widget.selectedClient?.id;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isSelected
                                ? Colors.green
                                : Colors.blue[100],
                            child: Text(
                              client.nom[0].toUpperCase(),
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.blue[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            client.nom,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (client.telephone != null)
                                Text(client.telephone!),
                              if (client.totalCredit > 0)
                                Text(
                                  'Crédit: ${client.totalCredit.toStringAsFixed(0)} F',
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                          selected: isSelected,
                          selectedTileColor: Colors.green[50],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          onTap: () => widget.onClientSelected(client),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}