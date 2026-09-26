# Guide d'installation et de configuration (Kitob)

Ce document décrit pas à pas la procédure pour configurer, compiler et exécuter l'application **Kitob** sur émulateur ou terminal physique (Android / iOS).

---

## 1. Prérequis système

Assurez-vous de disposer des outils suivants sur votre poste de développement :

* **Flutter SDK :** version `3.19.0` ou supérieure (canal stable, compatible Dart 3.3+).
* **Git :** pour le clonage et la gestion de version.
* **Environnement Android :** Android Studio avec Android SDK Platform-Tools et un émulateur ou terminal physique sous **Android 5.0 (API 21)** au minimum.
* **Environnement iOS (macOS uniquement) :** Xcode 15+ avec CocoaPods installé (`sudo gem install cocoapods`).
* **Firebase CLI & FlutterFire :**
  ```bash
  npm install -g firebase-tools
  dart pub global activate flutterfire_cli
  ```

Vérifiez l'état de votre chaîne d'outils avant de poursuivre :
```bash
flutter doctor
```

## 2. Récupération du projet et dépendances

1. Clonez le dépôt et placez-vous à la racine :
```bash
git clone git@github.com:loucabaigneres/kitob.git
cd kitob
```

2. Téléchargez les paquets Dart et Flutter :
```bash
flutter pub get
```

## 3. Configuration des variables d'environnement (`.env`)

L'application utilise `flutter_dotenv` pour isoler les clés d'API et les jetons de sécurité.

1. Dupliquez le fichier d'exemple à la racine du projet :

```bash
cp .env.example .env
```

2. Renseignez les variables requises dans le fichier `.env` :

```bash
GOOGLE_BOOKS_API_KEY=AIzaSy...votre_cle_api_google_books
FIREBASE_APP_CHECK_DEBUG_TOKEN=votre-uuid-debug-token-app-check
```

### Obtention des clés :
- **Clé Google Books API** :
  1. Rendez-vous sur la [Console Google Cloud](https://console.cloud.google.com/).
  2. Activez l'API **Books API**.
  3. Créez un identifiant de type **Clé API** dans l'onglet Identifiants.
- **Jeton de débogage Firebase App Check** :
  1. Définissez un UUID arbitraire (ex. : généré via `uuidgen` sur votre machine).
  2. Rendez-vous sur la [Console Firebase](https://console.firebase.google.com/) -> **App Check** -> onglet **Applications**.
  3. Cliquez sur le menu contextuel (trois points) de votre application Android/iOS -> **Gérer les jetons de débogage**.
  4. Ajoutez le même UUID dans la liste des jetons autorisés.

## 4. Configuration Firebase

1. Authentifiez-vous sur le CLI Firebase :
```bash
firebase login
```

2. Générez la configuration native multiplateforme :
```bash
flutterfire configure
```
  - Sélectionnez votre projet Firebase.
  - Cochez **Android** et **iOS**.
  - Cette commande génère `lib/firebase_options.dart`, ainsi que `android/app/google-services.json` et `ios/Runner/GoogleService-Info.plist`.

3. **Activer les services dans la console Firebase :**
  - **Authentication :** activez le fournisseur **Anonyme** et le fournisseur **Adresse e-mail/Mot de passe**.
  - **Cloud Firestore :** créez la base de données et appliquez les règles d'isolation utilisateur :
  ```plaintext
  rules_version = '2';
  service cloud.firestore {
    match /databases/{database}/documents {
      match /users/{userId}/books/{bookId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
  ```
  - **AI Logic :** dans la section **Build** -> **AI Logic**, activez l'accès à l'API Gemini.

## 5. Génération du code local (Isar Database)

Le schéma de la base de données locale repose sur la génération de code via `build_runner`. Exécutez la commande suivante pour compiler `lib/models/book.g.dart` :
```bash
dart run build_runner build --delete-conflicting-outputs
```
  Note : _Cette commande doit être relancée si vous modifiez la structure de la classe_ `@collection Book`.

## 6. Lancement de l'application

### Sur Android (Émulateur ou appareil physique) :

```bash
flutter run -d android
```

### Sur iOS (Simulateur ou iPhone) :
```bash
# Installation préalable des pods iOS
cd ios && pod install && cd ..

# Lancement
flutter run -d ios
```

Rappel sur le scanner caméra :
- _Sur simulateur (où le capteur optique n'est pas accessible), utilisez le bouton Galerie (icône photo) dans l'écran de scan pour charger une image de couverture de test._
- _Sur terminal physique, l'autorisation d'accès à la caméra vous sera demandée dès la première ouverture de l'écran de scan._

## 7. Résolution des problèmes courants (_Troubleshooting_)

- **Erreur d'asset `.env` manquant :**
Si Flutter lève une exception indiquant que `.env` est introuvable, arrêtez complètement le processus de compilation et relancez `flutter run`. L'ajout d'un asset dans `pubspec.yaml` nécessite une compilation complète du bundle.

- **Erreur d'App Check (403 Forbidden sur l'IA) :**
Vérifiez que le jeton défini dans `.env` correspond exactement à celui enregistré dans l'onglet App Check de la console Firebase.

- **Erreur de build Isar sur iOS :**
Exécutez `cd ios && pod repo update && pod install && cd ..`, puis nettoyez le cache avec `flutter clean && flutter pub get`.