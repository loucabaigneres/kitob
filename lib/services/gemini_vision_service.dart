import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';

class GeminiBookExtraction {
  final String title;
  final String author;
  final int? volumeNumber;

  const GeminiBookExtraction({
    required this.title,
    required this.author,
    this.volumeNumber,
  });

  factory GeminiBookExtraction.fromJson(Map<String, dynamic> json) {
    return GeminiBookExtraction(
      title: json['title'] as String? ?? 'Titre inconnu',
      author: json['author'] as String? ?? 'Auteur inconnu',
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
            'title': Schema.string(description: 'The exact title of the book'),
            'author': Schema.string(description: 'The author or creator name'),
            'volumeNumber': Schema.integer(
              description: 'The volume or tome number if specified, otherwise null',
              nullable: true,
            ),
          },
          optionalProperties: ['volumeNumber'],
        ),
      ),
      systemInstruction: Content.system(
        'You are an expert librarian and bibliophile. Analyze the uploaded picture  '
        'of a book cover or spine. Extract the book title, author, and volume number if present. '
        'Return only the requested structured JSON object without formatting or Markdown wrappers.'
      ),
    );
  }

  Future<GeminiBookExtraction> extractBookDetails(Uint8List imageBytes, String mimeType) async {
    final prompt = TextPart('Extract the book metadata from this image.');
    final imagePart = InlineDataPart(mimeType, imageBytes);

    final response = await _model.generateContent([
      Content.multi([prompt, imagePart])
    ]);

    final rawJson = response.text;
    if (rawJson == null || rawJson.isEmpty) {
      throw Exception('Gemini Vision returned an empty extraction response.');
    }

    final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
    return GeminiBookExtraction.fromJson(decoded);
  }
}
