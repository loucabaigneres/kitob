# Guide d'installation et de configuration (Kitob)

Ce document décrit la procédure pour installer, configurer et lancer **Kitob**.

Deux méthodes sont possibles :
1. **Configuration rapide (recommandée pour l'évaluation) :** utilisation des clés et fichiers d'accès Firebase déjà configurés (transmis via la plateforme de rendu).
2. **Configuration manuelle (alternative) :** liaison avec votre propre projet Firebase depuis zéro.

---

## 1. Prérequis système

Assurez-vous de disposer des outils suivants sur votre poste de développement :

* **Flutter SDK :** version `3.19.0` ou supérieure (canal stable, Dart 3.3+).
* **Environnement Android :** Android Studio avec Android SDK Platform-Tools et un émulateur ou terminal physique sous **Android 5.0 (API 21)** au minimum.
* **Environnement iOS (optionnel) :** Xcode 15+ et CocoaPods (`sudo gem install cocoapods`).
* **Git :** pour le clonage et la gestion de version.

Vérifiez votre environnement
```bash
flutter doctor
```

## 2. Récupération du dépôt & dépendances

1. Clonez le dépôt et placez-vous à la racine :
```bash
git clone git@github.com:loucabaigneres/kitob.git
cd kitob
```

2. Téléchargez les paquets Dart et Flutter :
```bash
flutter pub get
```

## 3. Méthode 1 : Démarrage rapide (Identifiants fournis pour la notation)

Pour tester directement l'application sur le backend du projet sans paramétrer de compte cloud, déposez les fichiers transmis sur la plateforme de rendu aux emplacements suivants :

### B. Emplacement des fichiers de configuration native

| **Fichier transmis**         | **Emplacement cible dans le projet**          | **Rôle**                                             |
|--------------------------|-------------------------------------------|--------------------------------------------------|
| `.env`                     | `kitob/.env` (racine du projet)             | Clé Google Books et debug token App Check        |
| `google-services.json`     | `kitob/android/app/google-services.json`    | Configuration Firebase Android (_cible de test_)   |
| `firebase_options.dart`    | `kitob/lib/firebase_options.dart`           | Initialisation FlutterFire dans le code          |
| `GoogleService-Info.plist` | `kitob/ios/Runner/GoogleService-Info.plist` | Configuration Firebase iOS (_fourni pour archive_) |

### Contenu du fichier `.env` à placer à la racine :

```bash
GOOGLE_BOOKS_API_KEY=<CLE_COMMUNIQUEE>
FIREBASE_APP_CHECK_DEBUG_TOKEN=<TOKEN_COMMUNIQUE>
```

## 4. Génération du schéma local (Isar Database)

Générez le code du schéma local avant de lancer la compilation :

```bash
dart run build_runner build --delete-conflicting-outputs
```
> _Note : Cette commande doit être relancée si vous modifiez la structure de la class_ `@collection Book`.

## 5. Lancement de l'application

Lancez l'application en mode débogage (nécessaire pour la validation App Check par jeton) :

### Sur Android (cible principale d'évaluation) :

```bash
flutter run -d android
```

### Sur iOS (si applicable) :

```bash
# Installation préalable des pods iOS
cd ios && pod install && cd ..

# Lancement
flutter run -d ios
```

> **Conseil pour le test du scanner :**
> **Sur terminal physique :** _visez directement la couverture ou la tranche d'un livre via le flux caméra_.
> **Sur émulateur :** _utilisez le bouton **Galerie** (à gauche du déclencheur) pour importer une image de couverture téléchargée sur l'appareil simulé_.

## 6. Méthode 2 : Configuration manuelle d'un nouveau projet

Si vous souhaitez brancher Kitob sur votre propre infrastructure cloud depuis zéro :

### A. Fichier d'environnement
Dupliquez le fichier d'exemple :
```bash
cp .env.example .env
```

### B. Clé API Google Books

1. Rendez-vous sur la [Console Google Cloud](https://console.cloud.google.com/).
2. Créez un projet ou sélectionnez un projet existant.
3. Dans la bibliothèque d'APIs, recherchez et activez **Books API** (Google Books API).
4. Accédez à la section **Identifiants** $\rightarrow$ **Créer des identifiants** $\rightarrow$ **Clé API**.
5. _(Recommandé)_ Restreignez la clé uniquement à l'API Books (sans restriction d'empreinte logicielle pour autoriser les tests en local).
6. Copiez cette clé dans votre fichier `.env` (`GOOGLE_BOOKS_API_KEY`).

### C. Configuration Firebase

1. Créez un projet sur la [Console Firebase](https://console.firebase.google.com/).
2. **Activation des services :**
  - **Authentication :** activez les fournisseurs **Anonyme** et **Adresse e-mail/Mot de passe**.
  - **Cloud Firestore :** créez la base et appliquez les règles d'accès suivantes :
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
  - **Firebase AI Logic :** activez Gemini via la rubrique _Build_ $\rightarrow$ _AI Logic_.
3. **Liaison CLI :**
```bash
npm install -g firebase-tools
dart pub global activate flutterfire_cli
firebase login
flutterfire configure
```
4. **App Check :**
  - Générez un UUID (par exemple via la commande `uuidgen`).
  - Renseignez cet UUID dans votre fichier `.env` (`FIREBASE_APP_CHECK_DEBUG_TOKEN`).
  - Dans la console Firebase $\rightarrow$ **App Check** $\rightarrow$ **Applications**, cliquez sur le menu de votre application Android/iOS $\rightarrow$ **Gérer les jetons de débogage**, et collez-y ce même UUID.

## 7. Résolution des incidents (Troubleshooting)

- **Erreur `Missing or insufficient permissions` (Firestore) :**
  - Vérifiez que les règles de sécurité Firestore autorisent bien l'UID de l'utilisateur connecté sur son propre sous-dossier `users/{userId}/books/{bookId}`.

**Erreur `403 Forbidden` lors de l'appel Gemini :**
  - Assurez-vous d'avoir exécuté l'application en mode debug (`flutter run`) afin que le jeton App Check présent dans le `.env` soit transmis aux serveurs Google.

**Fichier `.env` non détecté :**
  - Après l'ajout du fichier `.env`, redémarrez entièrement le processus de compilation (`flutter run`) pour que l'asset soit réintégré dans le bundle applicatif.
