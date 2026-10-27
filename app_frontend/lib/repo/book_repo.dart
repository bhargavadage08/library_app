import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constant/api_constants.dart';
import '../models/book_model.dart';
import '../models/reading_models.dart';
import 'auth_repo.dart';

class BookRepository {
  static const String gutendexBaseUrl = 'https://gutendex.com/books/';

  /// Fetches books from both backend PostgreSQL library and Gutendex catalog
  Future<List<Book>> fetchBooks({String query = '', String? category}) async {
    List<Book> books = [];

    // 1. Try fetching from FastAPI Backend
    try {
      final backendUri = Uri.parse('${ApiConstants.apiV1}/books').replace(
        queryParameters: {
          if (query.trim().isNotEmpty) 'query': query.trim(),
          if (category != null && category.trim().isNotEmpty) 'category': category.trim(),
          'limit': '50',
        },
      );

      final backendResp = await http
          .get(backendUri, headers: AuthService().authHeaders)
          .timeout(const Duration(seconds: 4));

      if (backendResp.statusCode == 200) {
        final list = jsonDecode(utf8.decode(backendResp.bodyBytes)) as List? ?? [];
        final backendBooks = list
            .map((item) => Book.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
        books.addAll(backendBooks);
      }
    } catch (_) {
      // Backend temporarily unreachable or offline; fallback to Gutendex catalog
    }

    // 2. Fetch additional catalog from Gutendex to provide rich browsing
    try {
      final gutendexUri = Uri.parse(gutendexBaseUrl).replace(
        queryParameters: {
          'languages': 'en',
          if (query.trim().isNotEmpty)
            'search': query.trim()
          else if (category != null && category.trim().isNotEmpty)
            'topic': category.trim(),
        },
      );

      final gutendexResp =
          await http.get(gutendexUri).timeout(const Duration(seconds: 15));

      if (gutendexResp.statusCode == 200) {
        final data = jsonDecode(gutendexResp.body) as Map<String, dynamic>;
        final results = data['results'] as List? ?? [];
        final existingIds = books.map((b) => b.id).toSet();

        for (final item in results) {
          final b = Book.fromJson(Map<String, dynamic>.from(item as Map));
          if (!existingIds.contains(b.id)) {
            books.add(b);
            existingIds.add(b.id);
          }
        }
      }
    } catch (_) {
      // If Gutendex fails or is slow, return what backend has
    }

    if (books.isEmpty && query.trim().isNotEmpty) {
      throw Exception('No books found for "$query".');
    }

    return books;
  }

  /// Extracts readable text/HTML format URL from Book model if available
  String? getPreferredFormatUrl(Book book) {
    final formats = book.formats;
    for (final key in [
      'text/plain; charset=utf-8',
      'text/plain',
      'text/html; charset=utf-8',
      'text/html',
    ]) {
      final val = formats[key];
      if (val is String && val.startsWith('http') && !val.contains('.zip')) {
        return val;
      }
    }
    return null;
  }

  /// Fetches a specific reading page from backend REST API
  Future<BookPage> fetchBookPage({
    required int bookId,
    int page = 1,
    int pageSize = 2500,
    Book? book,
  }) async {
    final Map<String, String> queryParams = {
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };

    if (book != null) {
      final formatUrl = getPreferredFormatUrl(book);
      if (formatUrl != null) queryParams['fallback_url'] = formatUrl;
      if (book.title.isNotEmpty) queryParams['fallback_title'] = book.title;
      if (book.authorName.isNotEmpty) queryParams['fallback_author'] = book.authorName;
    }

    final uri = Uri.parse('${ApiConstants.apiV1}/books/$bookId/pages')
        .replace(queryParameters: queryParams);

    try {
      final response = await http
          .get(uri, headers: AuthService().authHeaders)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return BookPage.fromJson(data);
      } else {
        // Fallback to client-side direct Gutenberg fetch
        return await _fetchClientSideFallback(
          bookId: bookId,
          page: page,
          pageSize: pageSize,
          book: book,
        );
      }
    } catch (_) {
      // If backend is unreachable or throws network exception, fallback to direct Gutenberg fetch
      return await _fetchClientSideFallback(
        bookId: bookId,
        page: page,
        pageSize: pageSize,
        book: book,
      );
    }
  }

  static final Map<int, List<String>> _clientSidePagesCache = {};

  Future<BookPage> _fetchClientSideFallback({
    required int bookId,
    required int page,
    required int pageSize,
    Book? book,
  }) async {
    int gutenbergId = bookId;
    const legacyMap = {1: 84, 2: 1342, 3: 64317, 4: 11, 5: 1661};
    if (legacyMap.containsKey(bookId)) {
      gutenbergId = legacyMap[bookId]!;
    } else if (book?.coverUrl != null) {
      final m = RegExp(r'/epub/(\d+)/').firstMatch(book!.coverUrl!);
      if (m != null) gutenbergId = int.tryParse(m.group(1)!) ?? bookId;
    }

    if (!_clientSidePagesCache.containsKey(gutenbergId)) {
      String? rawContent;
      final candidates = [
        'https://www.gutenberg.org/cache/epub/$gutenbergId/pg$gutenbergId.txt',
        'https://www.gutenberg.org/files/$gutenbergId/$gutenbergId-0.txt',
        if (book != null && getPreferredFormatUrl(book) != null)
          getPreferredFormatUrl(book)!,
      ];

      for (final url in candidates) {
        try {
          final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
          if (res.statusCode == 200 && res.body.length > 500) {
            rawContent = res.body;
            break;
          }
        } catch (_) {}
      }

      if (rawContent == null || rawContent.length < 500) {
        throw Exception(
          'Unable to load book text from server or Gutenberg mirror. '
          'Please ensure your internet connection or backend server is running.',
        );
      }

      _clientSidePagesCache[gutenbergId] = _paginateText(rawContent, pageSize: pageSize);
    }

    final pages = _clientSidePagesCache[gutenbergId]!;
    final total = pages.length;
    final clampedPage = page.clamp(1, total);

    return BookPage(
      bookId: bookId,
      title: book?.title ?? 'Book',
      author: book?.authorName ?? 'Unknown Author',
      page: clampedPage,
      pageSize: pageSize,
      totalPages: total,
      totalCharacters: pages.fold(0, (sum, p) => sum + p.length),
      content: pages[clampedPage - 1],
      hasPrev: clampedPage > 1,
      hasNext: clampedPage < total,
      isAppGenerated: true,
    );
  }

  static List<String> _paginateText(String text, {int pageSize = 2500}) {
    String clean = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
    final startMatch = RegExp(
      r'\*\*\*\s*START OF TH(E|IS) PROJECT GUTENBERG[^\*]*\*\*\*|\*END\*THE SMALL PRINT!',
      caseSensitive: false,
    ).firstMatch(clean);
    if (startMatch != null) {
      clean = clean.substring(startMatch.end).trim();
    }
    final endMatch = RegExp(
      r'\*\*\*\s*END OF TH(E|IS) PROJECT GUTENBERG[^\*]*\*\*\*|End of the Project Gutenberg|End of Project Gutenberg',
      caseSensitive: false,
    ).firstMatch(clean);
    if (endMatch != null) {
      clean = clean.substring(0, endMatch.start).trim();
    }

    if (clean.length < 200 && text.length > 500) {
      clean = text.replaceAll('\r\n', '\n').trim();
    }

    final List<String> pages = [];
    int start = 0;
    final totalLen = clean.length;

    while (start < totalLen) {
      if (start + pageSize >= totalLen) {
        final chunk = clean.substring(start).trim();
        if (chunk.isNotEmpty) pages.add(chunk);
        break;
      }
      int target = start + pageSize;
      int pBreak = clean.lastIndexOf('\n\n', (target + 300).clamp(0, totalLen));
      int splitAt;
      if (pBreak != -1 && pBreak >= target - 600) {
        splitAt = pBreak + 2;
      } else {
        int sBreak = -1;
        for (final punct in ['. ', '.\n', '? ', '!\n']) {
          final idx = clean.lastIndexOf(punct, target);
          if (idx > sBreak) sBreak = idx;
        }
        if (sBreak != -1 && sBreak >= target - 400) {
          splitAt = sBreak + 1;
        } else {
          int space = clean.lastIndexOf(' ', target);
          splitAt = (space != -1 && space >= target - 200) ? space + 1 : target;
        }
      }
      final chunk = clean.substring(start, splitAt).trim();
      if (chunk.isNotEmpty) pages.add(chunk);
      start = splitAt;
      while (start < totalLen && clean[start].trim().isEmpty) {
        start++;
      }
    }
    return pages.isEmpty ? ['No content available for this book.'] : pages;
  }

  /// Retrieves saved reading progress for a book from backend
  Future<BookProgress?> getReadingProgress(int bookId) async {
    final uri = Uri.parse('${ApiConstants.apiV1}/books/$bookId/progress');
    try {
      final response = await http
          .get(uri, headers: AuthService().authHeaders)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return BookProgress.fromJson(data);
      }
    } catch (_) {
      // Non-critical, ignore error on progress fetch failure
    }
    return null;
  }

  /// Persists reading progress to backend PostgreSQL
  Future<void> saveReadingProgress({
    required int bookId,
    required int page,
    required int totalPages,
  }) async {
    final uri = Uri.parse('${ApiConstants.apiV1}/books/$bookId/progress');
    try {
      await http
          .put(
            uri,
            headers: AuthService().authHeaders,
            body: jsonEncode({
              'current_page': page,
              'total_pages': totalPages,
            }),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      // Progress saving operates in background, non-blocking
    }
  }

  /// Toggles favorite status on backend
  Future<bool> toggleFavorite(int bookId) async {
    final uri = Uri.parse('${ApiConstants.apiV1}/books/$bookId/favorite');
    try {
      final response = await http
          .post(uri, headers: AuthService().authHeaders)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['is_favorite'] as bool? ?? false;
      }
    } catch (_) {}
    return false;
  }

  /// Retrieves user favorites from backend
  Future<List<Book>> fetchFavorites() async {
    final uri = Uri.parse('${ApiConstants.apiV1}/books/favorites');
    try {
      final response = await http
          .get(uri, headers: AuthService().authHeaders)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final list = jsonDecode(utf8.decode(response.bodyBytes)) as List? ?? [];
        return list
            .map((item) => Book.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Backwards-compatible content retrieval
  Future<String> fetchBookContent(Book book) async {
    final page = await fetchBookPage(bookId: book.id, page: 1, pageSize: 50000, book: book);
    return page.content;
  }
}
