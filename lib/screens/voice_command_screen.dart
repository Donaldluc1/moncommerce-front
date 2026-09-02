// lib/screens/voice_command_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/voice_service.dart';
import '../services/api_service.dart';

class VoiceCommandScreen extends StatefulWidget {
  const VoiceCommandScreen({super.key});

  @override
  State<VoiceCommandScreen> createState() => _VoiceCommandScreenState();
}

class _VoiceCommandScreenState extends State<VoiceCommandScreen>
    with SingleTickerProviderStateMixin {
  final VoiceService _voiceService = VoiceService();
  final ApiService _apiService = ApiService();

  bool _isListening = false;
  bool _isProcessing = false;
  String _transcribedText = '';
  String _resultMessage = '';
  bool _hasResult = false;
  bool _isSuccess = false;

  // Moteurs IA proposés par le backend (seuls les moteurs configurés sont listés)
  List<Map<String, dynamic>> _providers = [];
  String? _selectedProvider;

  static const _providerPrefsKey = 'ai_provider';
  static const _providerLabels = {
    'claude': 'Claude',
    'chatgpt': 'ChatGPT',
    'deepseek': 'DeepSeek',
  };

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _initializeVoice();
    _loadProviders();
  }

  Future<void> _initializeVoice() async {
    await _voiceService.initialize();
  }

  Future<void> _loadProviders() async {
    try {
      await _apiService.loadToken();
      final result = await _apiService.getAiProviders();

      final available = (result['providers'] as List)
          .cast<Map<String, dynamic>>()
          .where((p) => p['available'] == true)
          .toList();

      // Restaurer le dernier choix s'il est toujours disponible
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_providerPrefsKey);
      final names = available.map((p) => p['name']).toList();

      String? selected;
      if (saved != null && names.contains(saved)) {
        selected = saved;
      } else if (available.isNotEmpty) {
        selected = available.firstWhere(
          (p) => p['isDefault'] == true,
          orElse: () => available.first,
        )['name'];
      }

      if (mounted) {
        setState(() {
          _providers = available;
          _selectedProvider = selected;
        });
      }
    } catch (_) {
      // Sans liste, le backend applique son moteur par défaut : pas bloquant
    }
  }

  Future<void> _selectProvider(String name) async {
    setState(() => _selectedProvider = name);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_providerPrefsKey, name);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _voiceService.dispose();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      // Arrêter l'écoute
      await _voiceService.stopListening();
      setState(() => _isListening = false);
    } else {
      // Réinitialiser
      setState(() {
        _transcribedText = '';
        _resultMessage = '';
        _hasResult = false;
      });

      // Démarrer l'écoute
      await _voiceService.startListening(
        onResult: _handleVoiceResult,
        onError: (error) {
          setState(() {
            _isListening = false;
            _resultMessage = error;
            _hasResult = true;
            _isSuccess = false;
          });
        },
      );

      setState(() => _isListening = true);
    }
  }

  Future<void> _handleVoiceResult(String text) async {
    setState(() {
      _transcribedText = text;
      _isListening = false;
      _isProcessing = true;
    });

    try {
      // Envoyer à l'API (avec le moteur IA choisi)
      await _apiService.loadToken();
      final result = await _apiService.sendVoiceCommand(
        text,
        provider: _selectedProvider,
      );

      setState(() {
        _isProcessing = false;
        _hasResult = true;
        _isSuccess = result['success'];
        _resultMessage = result['message'];
      });

      // Confirmation vocale
      if (_isSuccess) {
        await _voiceService.speak(result['message']);
      }

    } catch (e) {
      setState(() {
        _isProcessing = false;
        _hasResult = true;
        _isSuccess = false;
        _resultMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Commande Vocale IA'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Instructions
            Card(
              color: Colors.deepPurple[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.deepPurple[700]),
                        const SizedBox(width: 8),
                        const Text(
                          'Exemples de commandes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildExample('📦 Vente de 5000 francs en espèces'),
                    _buildExample('💳 Vente à crédit de 3000 F pour Jean Kouassi'),
                    _buildExample('💸 Dépense de 2000 francs pour le transport'),
                    _buildExample('👤 Créer un client Marie Koné 0708090102'),
                  ],
                ),
              ),
            ),
            
            // Sélecteur de moteur IA (affiché seulement s'il y a un vrai choix)
            if (_providers.length > 1) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.smart_toy, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Moteur IA :',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      children: _providers.map((p) {
                        final name = p['name'] as String;
                        final isSelected = name == _selectedProvider;
                        return ChoiceChip(
                          label: Text(
                            _providerLabels[name] ?? name,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.white : Colors.grey[800],
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: Colors.deepPurple,
                          visualDensity: VisualDensity.compact,
                          onSelected: _isProcessing
                              ? null
                              : (_) => _selectProvider(name),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ] else
              const SizedBox(height: 40),

            // Bouton micro
            GestureDetector(
              onTap: _isProcessing ? null : _toggleListening,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _isListening
                      ? LinearGradient(
                          colors: [Colors.red[400]!, Colors.red[600]!],
                        )
                      : LinearGradient(
                          colors: [Colors.deepPurple[400]!, Colors.deepPurple[600]!],
                        ),
                  boxShadow: [
                    BoxShadow(
                      color: _isListening
                          ? Colors.red.withOpacity(0.5)
                          : Colors.deepPurple.withOpacity(0.5),
                      blurRadius: _isListening ? 30 : 20,
                      spreadRadius: _isListening ? 10 : 5,
                    ),
                  ],
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      )
                    : Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        size: 70,
                        color: Colors.white,
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // Texte d'état
            Text(
              _isListening
                  ? 'Parlez maintenant...'
                  : _isProcessing
                      ? 'Traitement en cours...'
                      : 'Appuyez sur le micro',
              style: TextStyle(
                fontSize: 18,
                color: _isListening ? Colors.red : Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 40),

            // Texte transcrit
            if (_transcribedText.isNotEmpty)
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.hearing, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Vous avez dit :',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _transcribedText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Résultat
            if (_hasResult)
              Card(
                color: _isSuccess ? Colors.green[50] : Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isSuccess ? Icons.check_circle : Icons.error,
                            color: _isSuccess ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isSuccess ? 'Succès !' : 'Erreur',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: _isSuccess ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _resultMessage,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),

            const Spacer(),

            // Bouton retour
            if (_hasResult && _isSuccess)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  label: const Text(
                    'Retour à l\'accueil',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExample(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          const Icon(Icons.mic, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}