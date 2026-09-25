import 'package:dio/dio.dart';

import '../constants/api_constants.dart';

class GoogleBooksMetadata {
  final String title;
  final String author;
  final String? isbn;
  final String? coverUrl;
  final String? publisher;
  final int? pageCount;
  final String? synopsis;

  const GoogleBooksMetadata({
    required this.title,
    required this.author,
    this.isbn,
    this.coverUrl,
    this.publisher,
    this.pageCount,
    this.synopsis,
  });
}

class GoogleBooksService {
  final Dio _dio;

  GoogleBooksService([Dio? dio])
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConstants.googleBooksApiBaseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
              ),
            );
  
  Future<GoogleBooksMetadata?> searchBook({
    required String title,
    required String author,
  }) async {
    try {
      final query = 'intitle:$title+inauthor:$author';

      final queryParams = <String, dynamic>{
        'q': query,
        'maxResults': 1,
        'printType': 'books',
      };

      final apiKey = ApiConstants.googleBooksApiKey;
      if (apiKey.isNotEmpty) {
        queryParams['key'] = apiKey;
      }

      final response = await _dio.get(
        '/volumes',
        queryParameters: queryParams
      );

      final items = response.data['items'] as List<dynamic>?;
      if (items == null || items.isEmpty) {
        return null;
      }

      final volumeInfo = items.first['volumeInfo'] as Map<String, dynamic>;

      String? isbn;
      final identifiers = volumeInfo['industryIdentifiers'] as List<dynamic>?;
      if (identifiers != null) {
        for (final id in identifiers) {
          if (id['type'] == 'ISBN_13') {
            isbn = id['identifier'] as String?;
            break;
          } else if (id['type'] == 'ISBN_10') {
            isbn ??= id['identifier'] as String?;
          }
        }
      }

      String? coverUrl;
      final imageLinks = volumeInfo['imageLinks'] as Map<String, dynamic>?;
      if (imageLinks != null) {
        final rawThumbnail = imageLinks['thumbnail'] as String? ?? imageLinks['smallThumbnail'] as String?;
        if (rawThumbnail != null) {
          coverUrl = rawThumbnail.replaceAll('http://', 'https://');
        }
      }

      final authorsList = volumeInfo['authors'] as List<dynamic>?;
      final resolvedAuthor = (authorsList != null && authorsList.isNotEmpty)
          ? authorsList.first as String
          : author;
      
      return GoogleBooksMetadata(
        title: volumeInfo['title'] as String? ?? title,
        author: resolvedAuthor,
        isbn: isbn,
        coverUrl: coverUrl,
        publisher: volumeInfo['publisher'] as String?,
        pageCount: volumeInfo['pageCount'] as int?,
        synopsis: volumeInfo['description'] as String?,
      );
    } on DioException catch (e) {
      throw Exception('Network error while querying Google Books API: ${e.message}');
    }
  }
}
