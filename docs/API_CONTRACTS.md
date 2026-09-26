# Spécification des contrats d'API et SDKs (Kitob)

Ce document formalise les contrats d'échange, structures de données et schémas JSON utilisés par **Kitob** pour communiquer avec ses services tiers et ses moteurs de persistance.

---

## 1. Firebase AI Logic — Gemini 3.5 Flash-Lite (Vision)

Le service d'analyse d'image s'appuie sur le modèle multimodal `gemini-3.5-flash-lite` via le SDK `firebase_ai`. Pour fiabiliser la désérialisation, le modèle est bridé par un schéma de sortie forcé (*Structured Outputs* en `application/json`).

### A. Données transmises (Requête)

* **Mode d'inférence :** `generateContent` multimodal.
* **Parts :**
  1. `TextPart` : consigne d'analyse (« Analyze this picture and extract book metadata: »).
  2. `InlineDataPart` : flux d'octets brut de l'image capturée (`Uint8List`) associé à son type MIME (`image/jpeg` ou `image/png`).
* **Format d'image recommandé :** JPEG compressé (qualité 85 %, résolution maximale 1600×1600 px).

### B. Schéma de réponse forcé (`responseSchema`)

Le schéma JSON strict configuré sur l'instance `GenerativeModel` est défini comme suit :

```json
{
  "$schema": "[http://json-schema.org/draft-07/schema#](http://json-schema.org/draft-07/schema#)",
  "title": "GeminiBookExtraction",
  "type": "object",
  "properties": {
    "isBook": {
      "type": "boolean",
      "description": "True if a physical book cover or spine is clearly identified in the image, false otherwise"
    },
    "title": {
      "type": "string",
      "description": "The title of the book, or null if unreadable or not a book"
    },
    "author": {
      "type": "string",
      "description": "The author name, or null if unreadable or not a book"
    },
    "volumeNumber": {
      "type": "integer",
      "description": "The volume number if visible, otherwise null"
    }
  },
  "required": ["isBook"]
}
```

### C. Exemples de charge utile renvoyée


#### Cas 1 : Livre reconnu avec succès

```json
{
  "isBook": true,
  "title": "Dune",
  "author": "Frank Herbert",
  "volumeNumber": 1
}
```

#### Cas 2 : Absence de livre ou image non pertinente (Faux positif)

```json
{
  "isBook": false
}
```

## 2. API Google Books (Volumes v1)

Le client HTTP `Dio` interroge le catalogue public de Google Books pour enrichir les informations issues de l'extraction visuelle.

### A. Endpoint & Paramètres
- URL de base : `https://www.googleapis.com/books/v1`
- Chemin : `/volumes`
- Méthode : `GET`
- Headers : `Accept: application/json`

| Paramètre  | Type    | Présence  | Description                           | Exemple                             |
|------------|---------|-----------|---------------------------------------|-------------------------------------|
| `q`          | `string`  | Requis    | Requête qualifiée par préfixes        | `intitle:Dune+inauthor:Frank Herbert` |
| `maxResults` | `integer` | Requis    | Limite le résultat au premier élément | `1`                                   |
| `printType`  | `string`  | Requis    | Filtre sur les livres imprimés        | `books`                               |
| `key`        | `string`  | Optionnel | Clé d'API Google Cloud issue de `.env`  | `AIzaSy...`                           |

### B. Contrat de réponse extrait (`volumeInfo`)

L'application filtre la réponse brute pour hydrater le DTO interne `GoogleBookMetadata` :

```json
{
  "kind": "books#volumes",
  "totalItems": 1,
  "items": [
    {
      "id": "_ojXNuzgHRcC",
      "volumeInfo": {
        "title": "Dune",
        "authors": ["Frank Herbert"],
        "publisher": "Chilton Books",
        "description": "Set on the desert planet Arrakis, Dune is the story of the boy Paul Atreides...",
        "industryIdentifiers": [
          {
            "type": "ISBN_10",
            "identifier": "0441172717"
          },
          {
            "type": "ISBN_13",
            "identifier": "9780441172719"
          }
        ],
        "pageCount": 412,
        "imageLinks": {
          "smallThumbnail": "[http://books.google.com/books/content?id=_ojXNuzgHRcC&printsec=frontcover&img=1&zoom=5](http://books.google.com/books/content?id=_ojXNuzgHRcC&printsec=frontcover&img=1&zoom=5)...",
          "thumbnail": "[http://books.google.com/books/content?id=_ojXNuzgHRcC&printsec=frontcover&img=1&zoom=1](http://books.google.com/books/content?id=_ojXNuzgHRcC&printsec=frontcover&img=1&zoom=1)..."
        }
      }
    }
  ]
}
```

> **Traitement appliqué par Kitob :**
> - _L'ISBN-13 est extrait prioritairement par rapport à l'ISBN-10._
> - _L'URL du thumbnail est systématiquement migrée en protocole sécurisé (`http://` $\rightarrow$ `https://`)._

## 3. Schéma de données Cloud Firestore

L'arborescence NoSQL isole strictement les données de chaque utilisateur dans une sous-collection dédiée.

### A. Chemin de collection

```plaintext
users/{userId}/books/{remoteId}
```
- `{userId}` : identifiant Firebase Auth de l'utilisateur (`request.auth.uid`).
- `{remoteId}` : identifiant unique de document généré automatiquement par Firestore.

### B. Structure du document `Book`

| **Champ**        | **Type Firestore** | **Nullable** | **Description**                                        |
|--------------|----------------|----------|----------------------------------------------------|
| `remoteId`     | `String`         | Non      | Identifiant identique à l'ID du document           |
| `title`        | `String`         | Non      | Titre de l'ouvrage                                 |
| `author`       | `String`         | Non      | Nom de l'auteur                                    |
| `volumeNumber` | `Number (int)`   | Oui      | Numéro de tome le cas échéant                      |
| `isbn`         | `String`         | Oui      | Identifiant ISBN (10 ou 13)                        |
| `coverUrl`     | `String`         | Oui      | Lien HTTPS vers la couverture haute définition     |
| `publisher`    | `String`         | Oui      | Maison d'édition                                   |
| `pageCount`    | `Number (int)`   | Oui      | Nombre total de pages                              |
| `synopsis`     | `String`         | Oui      | Résumé complet de l'œuvre                          |
| `status`       | `String`         | Non      | Statut : `'owned'`, `'toRead'` ou `'wishlist'`           |
| `createdAt`    | `Timestamp`      | Non      | Date de première saisie                            |
| `updatedAt`    | `Timestamp`      | Non      | Horodatage utilisé pour le conflit _Last-Write-Wins_ |

## 4. Contrat du schéma local Isar Database

La collection locale Isar reproduit le modèle métier avec des index optimisés pour la recherche instantanée et le filtrage.

```dart
@collection
class Book {
  Id id = Isar.autoIncrement;

  @Index()
  String? remoteId;

  late String title;
  late String author;
  int? volumeNumber;

  @Index()
  String? isbn;

  String? coverUrl;
  String? localCoverPath;
  String? publisher;
  int? pageCount;
  String? synopsis;

  @Enumerated(EnumType.name)
  ReadingStatus status = ReadingStatus.owned;

  late DateTime createdAt;
  late DateTime updatedAt;

  bool isSynced = false;
}
```

- **Index sur** `remoteId` **:** permet de réconcilier les documents distants en $\mathcal{O}(1)$ lors de la phase _ _ de synchronisation.
- **Index sur** `isbn` **:** assure une détection instantanée des doublons locaux dès la capture du livre.