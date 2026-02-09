// lib/main.dart
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/subscription_screen.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser les formats de date français
  await initializeDateFormatting('fr_FR', null);
  
  runApp( MyApp());
}

class MyApp extends StatelessWidget {
  Future<bool> _checkAccess() async {
    try {
      final api = ApiService();
      await api.loadToken();
      final result = await api.checkSubscriptionAccess();
      return result['access']['hasAccess'] == true;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FutureBuilder<bool>(
        future: _checkAccess(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Si pas d'accès → Écran abonnement bloquant
          if (!snapshot.data!) {
            return const SubscriptionScreen(isTrialExpired: true);
          }

          // Accès OK → Home
          return const HomeScreen();
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.initialize();

    // Attendre 1 seconde pour le splash
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => authProvider.isAuthenticated
              ? const HomeScreen()
              : const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.store,
                size: 80,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Mon Commerce',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gérez votre activité facilement',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}