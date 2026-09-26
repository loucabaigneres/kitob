import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';

class GeminiBookExtraction {
  final bool isBook;
  final String? title;
  final String? author;
  final int? volumeNumber;

  const GeminiBookExtraction({
    required this.isBook,
    this.title,
    this.author,
    this.volumeNumber,
  });

  factory GeminiBookExtraction.fromJson(Map<String, dynamic> json) {
    return GeminiBookExtraction(
      isBook: json['isBook'] as bool? ?? false,
      title: json['title'] as String?,
      author: json['author'] as String?,
      volumeNumber: json['volumeNumber'] as int?,
    );
  }
}

class GeminiVisionService {
  late final GenerativeModel _model;

  GeminiVisionService() {
    _model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-3.5-flash-lite',
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: Schema.object(
          properties: {
            'isBook': Schema.boolean(
              description: 'True if a physical book cover or spine is clearly identified in the image, false otherwise'
            ),
            'title': Schema.string(
              description: 'The title of the book, or null if unreadable or not a book',
              nullable: true,
            ),
            'author': Schema.string(
              description: 'The author name, or null if unreadable or not a book',
              nullable: true,
            ),
            'volumeNumber': Schema.integer(
              description: 'The volume number if visible, otherwise null',
              nullable: true,
            ),
          },
          optionalProperties: ['title', 'author', 'volumeNumber'],
        ),
      ),
      systemInstruction: Content.system(
        'You are an expert librarian and bibliophile. Examine the image. First, determine if a book cover or spine is present. '
        'If no book is visible, set isBook to false and omit other fields. '
        'If a book is visible, extract the title, author, and volume number with high precision.',
      ),
    );
  }

  Future<GeminiBookExtraction> extractBookDetails(Uint8List imageBytes, String mimeType) async {
    final prompt = TextPart('Analyze this picture and extract book metadata.');
    final imagePart = InlineDataPart(mimeType, imageBytes);

    final response = await _model.generateContent([
      Content.multi([prompt, imagePart])
    ]);

    final rawJson = response.text;
    if (rawJson == null || rawJson.isEmpty) {
      throw Exception('L\'IA n\'a renvoyé aucune réponse.');
    }

    final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
    return GeminiBookExtraction.fromJson(decoded);
  }
}
