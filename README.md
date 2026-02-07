# 📱 Application Mobile - Gestion Commerce MVP

Application mobile Flutter pour gérer son commerce facilement.

## 🚀 Installation & Lancement

### Prérequis

- Flutter SDK 3.0+ installé ([Guide d'installation](https://flutter.dev/docs/get-started/install))
- Android Studio ou VS Code
- Un émulateur Android ou un téléphone physique

### Étapes d'installation

```bash
# 1. Naviguer dans le dossier
cd mobile

# 2. Installer les dépendances
flutter pub get

# 3. Vérifier que tout fonctionne
flutter doctor

# 4. Lancer l'application
flutter run
```

## ⚙️ Configuration

### Modifier l'URL de l'API

Avant de lancer l'app, modifier l'URL de l'API dans :

**`lib/config/api_config.dart`**

```dart
static const String baseUrl = 'https://votre-api-deployee.railway.app/api';
```

## 📱 Fonctionnalités

### 1. Authentification
- ✅ Inscription rapide (téléphone + mot de passe)
- ✅ Connexion
- ✅ Session persistante

### 2. Enregistrer une vente
- ✅ Montant en gros caractères
- ✅ Mode paiement : Cash ou Crédit
- ✅ Nom du client (optionnel)
- ✅ Interface ultra-simple

### 3. Enregistrer une dépense
- ✅ Montant
- ✅ Description simple
- ✅ Catégories prédéfinies

### 4. Gestion des crédits
- ✅ Liste des clients avec dette
- ✅ Total des crédits
- ✅ Enregistrer un paiement
- ✅ Mise à jour automatique

### 5. Tableau de bord
- ✅ Bénéfice du jour (coloré)
- ✅ Total ventes
- ✅ Total dépenses
- ✅ Accès rapide aux actions

### 6. Historique
- ✅ Liste des ventes
- ✅ Liste des dépenses
- ✅ Dates et montants clairs

## 🎨 Captures d'écran

```
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│  Connexion  │  │   Accueil   │  │Nouvelle Vente│
│             │  │             │  │             │
│  [Téléphone]│  │ Bénéfice:   │  │  Montant:   │
│  [Mot passe]│  │  +8000 F    │  │  [______] F │
│             │  │             │  │             │
│ [Connexion] │  │ Ventes: ... │  │ [Cash/Crédit]│
└─────────────┘  └─────────────┘  └─────────────┘
```

## 🏗️ Architecture

```
lib/
├── config/           # Configuration (API)
├── models/           # Modèles de données
├── services/         # Services API
├── providers/        # State management
├── screens/          # Écrans de l'app
└── main.dart         # Point d'entrée
```

## 🔧 Build pour production

### Android

```bash
# Build APK
flutter build apk --release

# Build App Bundle (pour Play Store)
flutter build appbundle --release
```

L'APK se trouvera dans : `build/app/outputs/flutter-apk/app-release.apk`

### iOS (si Mac)

```bash
flutter build ios --release
```

## 📦 Dépendances principales

- **provider** : State management simple
- **http** : Requêtes API
- **shared_preferences** : Stockage local
- **intl** : Formatage dates/montants
- **google_fonts** : Polices

## 🐛 Debugging

### Problèmes courants

**1. Erreur de connexion à l'API**
- Vérifier l'URL dans `api_config.dart`
- Vérifier que le backend est démarré
- Sur émulateur Android : utiliser `10.0.2.2:3000` au lieu de `localhost:3000`

**2. Build qui échoue**
```bash
flutter clean
flutter pub get
flutter run
```

**3. Problème de permission réseau (Android)**
Vérifier `android/app/src/main/AndroidManifest.xml` :
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

## 🎯 Prochaines améliorations (Phase 2)

- [ ] Mode hors-ligne avec synchronisation
- [ ] Notifications de rappel
- [ ] Graphiques de statistiques
- [ ] Export PDF des rapports
- [ ] Photo de produits
- [ ] Gestion du stock

## 📝 Notes importantes

### Sécurité
- Le token JWT est stocké localement
- Utiliser HTTPS en production
- Ne jamais commit les tokens/secrets

### Performance
- L'app charge les 50 dernières entrées par défaut
- Pagination à implémenter pour grosse volumétrie

### UX Mobile-first
- Gros boutons (minimum 48x48 dp)
- Textes lisibles (minimum 16sp)
- Pas de scroll horizontal
- Navigation simple (max 3 niveaux)

## 🚀 Déploiement en production

### Play Store (Android)

1. **Créer un compte développeur** (25$ one-time)
2. **Générer le keystore** :
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

3. **Configurer dans** `android/key.properties`

4. **Build & Upload** :
```bash
flutter build appbundle --release
```

### App Store (iOS)

1. Compte Apple Developer (99$/an)
2. Certificats et profils
3. Build avec Xcode
4. Upload via App Store Connect

## 💡 Conseils produit

### Pour vendre l'app

- Démo de 2 minutes maximum
- Focus sur "enregistrer vente" et "voir bénéfice"
- Montrer la simplicité (3 clics)
- Prix clair dès le départ

### Onboarding utilisateur

1. Écran d'accueil explicatif
2. 3-4 slides de présentation
3. Exemple pré-rempli
4. Bouton "J'ai compris, commencer"

## 📞 Support

Pour toute question :
- Créer une issue sur GitHub
- Email : support@moncommerce.com
- WhatsApp : +225 XX XX XX XX

---

**Version** : 1.0.0
**Dernière mise à jour** : Février 2026