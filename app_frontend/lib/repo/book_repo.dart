import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book_model.dart';

class BookRepository {
  static const String baseUrl = 'https://gutendex.com/books/';

  Future<List<Book>> fetchBooks({String query = ''}) async {
    final uri = Uri.parse(baseUrl).replace(
      queryParameters: {
        'languages': 'en',
        if (query.trim().isNotEmpty) 'search': query.trim(),
      },
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Failed to load books: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = data['results'] as List? ?? [];

    return results
        .map((item) => Book.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<String> fetchBookContent(Book book) async {
    final formats = book.formats;

    // Find a supported plain-text format.
    String? textUrl;

    for (final entry in formats.entries) {
      final key = entry.key.toLowerCase();
      final value = entry.value;

      if (value is String &&
          value.startsWith('https://') &&
          key.startsWith('text/plain') &&
          !key.contains('zip')) {
        textUrl = value;
        break;
      }
    }

    if (textUrl == null) {
      throw Exception('No plain-text version is available for this book.');
    }

    try {
      final response = await http
          .get(Uri.parse(textUrl))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception(
          'The book server returned HTTP ${response.statusCode}.',
        );
      }

      final content = utf8.decode(response.bodyBytes, allowMalformed: true);

      if (content.trim().isEmpty) {
        throw Exception('The book text is empty.');
      }

      return content;
    } catch (error) {
      throw Exception(
        'Could not download the book text. '
        'The server may be unavailable or blocking browser requests. '
        'Details: $error',
      );
    }
  }
}
