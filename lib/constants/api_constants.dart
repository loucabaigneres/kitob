import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class ApiConstants {
  // Google Books API
  static const String googleBooksApiBaseUrl = 'https://www.googleapis.com/books/v1';

  // Environment variables
  static String get googleBooksApiKey => dotenv.env['GOOGLE_BOOKS_API_KEY'] ?? '';
  static String? get appCheckDebugToken => dotenv.env['FIREBASE_APP_CHECK_DEBUG_TOKEN'];
}
