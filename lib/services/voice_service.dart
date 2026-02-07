// lib/services/voice_service.dart
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  // Instances
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  
  // État
  bool _isInitialized = false;
  bool _isListening = false;
  String _lastWords = '';

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  String get lastWords => _lastWords;

  VoiceService() {
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _initializeTts();
  }

  /// Initialiser Text-to-Speech
  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage("fr-FR");
    await _flutterTts.setSpeechRate(0.5); // Vitesse normale
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  /// Initialiser la reconnaissance vocale
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Demander la permission
      final status = await Permission.microphone.request();
      
      if (!status.isGranted) {
        print('[VOICE] Permission micro refusée');
        return false;
      }

      // Initialiser le speech-to-text
      _isInitialized = await _speech.initialize(
        onError: (error) => print('[VOICE] Erreur: ${error.errorMsg}'),
        onStatus: (status) => print('[VOICE] Statut: $status'),
      );

      print('[VOICE] Initialisé: $_isInitialized');
      return _isInitialized;

    } catch (e) {
      print('[VOICE] Erreur initialisation: $e');
      return false;
    }
  }

  /// Démarrer l'écoute
  Future<void> startListening({
    required Function(String) onResult,
    Function(String)? onError,
  }) async {
    if (!_isInitialized) {
      final init = await initialize();
      if (!init) {
        onError?.call('Impossible d\'initialiser le micro');
        return;
      }
    }

    if (_isListening) {
      print('[VOICE] Déjà en écoute');
      return;
    }

    _lastWords = '';

    try {
      _isListening = true;
      
      await _speech.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords;
          print('[VOICE] Transcrit: $_lastWords');
          
          // Si résultat final
          if (result.finalResult) {
            onResult(_lastWords);
            stopListening();
          }
        },
        localeId: 'fr_FR', // Français
        listenMode: stt.ListenMode.confirmation, // Attendre confirmation
        cancelOnError: true,
        partialResults: true,
      );

      print('[VOICE] Écoute démarrée...');

    } catch (e) {
      print('[VOICE] Erreur écoute: $e');
      _isListening = false;
      onError?.call('Erreur lors de l\'écoute');
    }
  }

  /// Arrêter l'écoute
  Future<void> stopListening() async {
    if (!_isListening) return;

    await _speech.stop();
    _isListening = false;
    print('[VOICE] Écoute arrêtée');
  }

  /// Parler (Text-to-Speech)
  Future<void> speak(String text) async {
    try {
      print('[TTS] Parle: "$text"');
      await _flutterTts.speak(text);
    } catch (e) {
      print('[TTS] Erreur: $e');
    }
  }

  /// Arrêter de parler
  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
  }

  /// Nettoyer les ressources
  void dispose() {
    _speech.cancel();
    _flutterTts.stop();
  }

  /// Vérifier si la reconnaissance vocale est disponible
  Future<bool> isAvailable() async {
    return await _speech.initialize();
  }

  /// Obtenir les langues disponibles
  Future<List<stt.LocaleName>> getAvailableLanguages() async {
    return await _speech.locales();
  }
}