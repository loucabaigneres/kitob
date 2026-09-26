# Kitob — Gestionnaire de bibliothèque intelligent

**Kitob** est une application mobile de gestion de bibliothèque personnelle conçue avec une approche **offline-first**. Elle permet de numériser et de cataloguer une collection physique en quelques secondes grâce à la vision par ordinateur et à l'intelligence artificielle générative, tout en garantissant un fonctionnement intégral sans connexion internet.

## Fonctionnalités clés

- **Numérisation multimodale par IA :** flux caméra direct analysant instantanément la couverture ou la tranche d'un livre via **Gemini 3.5 Flash** (`firebase_ai`) avec extraction typée et détection des faux positifs (vérification de présence effective d'un livre).

- **Enrichissement automatique des métadonnées :** récupération transparente des informations bibliographiques via l'API **Google Books** (couverture haute résolution, résumé officiel, pagination, éditeur, ISBN).

- **Détection préventive des doublons :** comparaison en direct sur l'ISBN standardisé et sur la combinaison titre/auteur avant toute persistance locale.

- **Gestion du cycle de lecture :** organisation de la collection selon trois statuts clairs (_Possédé_, _À lire_, _Wishlist_) avec filtrage réactif et recherche plein texte instantanée.

- **Architecture offline-first absolue :** la base de données locale Isar constitue la source unique de vérité (_Single Source of Truth_). L'application reste réactive et exploitable à 100 % en mode avion.

- **Synchronisation Cloud bidirectionnelle :** persistance distante sur Cloud Firestore avec réconciliation des conflits par horodatage (_Last-Write-Wins_) et badge de statut d'attente en temps réel.

- **Authentification fluide et progressive :** session anonyme automatique dès l'installation, convertible à tout moment en compte Email/Mot de passe sécurisé (`linkWithCredential`) sans perte des volumes enregistrés.

- **Indicateurs et métriques d'activité :** tableau de bord éditorial calculant dynamiquement le volume d'ouvrages, le cumul des pages lues et la répartition de la collection.

## Direction artistique & Design

L'interface de Kitob s'éloigne des codes applicatifs utilitaires classiques pour adopter une ambiance éditoriale haut de gamme inspirée de la reliure d'art et des catalogues d'archives :

- **Typographie :** contraste soigné entre **Newsreader** (serif littéraire pour les titres et métadonnées d'auteur) et **Inter** (sans-serif technique pour les champs numériques et puces de tri).

- **Palette chromatique :** nuances organiques de papier non blanchi (`#F6FBF5`), réhaussées d'un terracotta profond (`#9F3C16`), d'un vert sauge laurier (`#376847`) et d'un ambre chaud (`#8D4B00`) pour les alertes de doublons.

- **Composants :** cartes au ratio livre 3:4 avec simulation d'ombrage de tranche, viseur de cadrage avec retour d'état pas-à-pas et fiches inférieures ergonomiques.

## Stack technique

| Domaine                       | Technologie retenue         | Rôle dans l'application                                                                           |
|-------------------------------|-----------------------------|---------------------------------------------------------------------------------------------------|
| **Framework**                 | Flutter 3.x / Dart 3.x      | Développement multiplateforme (iOS / Android)                                                     |
| **Gestion d'état**            | Flutter Riverpod 3.x        | Architecture réactive, `Notifier` et `AsyncNotifier` sans logique métier dans les widgets           |
| **Navigation**                | GoRouter 18.x               | Routage déclaratif et sous-routes paramétrées (`/book/:id`)                                       |
| **Persistance locale**        | Isar Community Edition      | Moteur NoSQL local ultra-rapide et streams d'écoute réactifs                                      |
| **Réseau**                    | Dio 5.x                     | Client HTTP typé avec timeouts et injection de clé d'API                                          |
| **Intelligence artificielle**  | Firebase AI Logic           | Inférence multimodale sur Gemini 1.5 Flash avec formats de sortie stricts ( _Structured Outputs_) |
| **Backend & Auth**            | Firebase (Auth & Firestore) | Gestion d'identité (invité -> email) et synchronisation distante NoSQL                            |
| **Sécurité**                  | Firebase App Check          | Protection de l'API IA contre les abus via tokens de débogage et attestations d'intégrité         |
| **Matériel & Médias**         | Camera & Image Picker       | Contrôle du flux vidéo du capteur physique et sélecteur de fichiers de galerie                      |

## Structure de la documentation

Pour faciliter l'évaluation technique et le déploiement du projet, la documentation détaillée est regroupée dans le dossier `docs/` :

1. [README.md](README.md) : présentation globale, proposition de valeur et technologies.
2. [Guide d'installation et configuration](docs/SETUP.md) : prérequis, variables d'environnement, Firebase et lancement pas-à-pas.
3. [Architecture logicielle](docs/ARCHITECTURE.md) : découpage en couches, gestion d'état Riverpod, persistance Isar et synchronisation Firestore.
4. [Contrats d'API et SDKs](docs/API_CONTRACTS.md) : schémas d'entrée/sortie Gemini Vision, API Google Books et modèle de données NoSQL.