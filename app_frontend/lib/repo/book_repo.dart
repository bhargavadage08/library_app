import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constant/api_constants.dart';
import '../models/book_model.dart';
import '../models/reading_models.dart';
import 'auth_repo.dart';

class BookRepository {
  static const String gutendexBaseUrl = 'https://gutendex.com/books/';

  static final List<Book> _allCachedBooks = [];

  /// Fetches all books directly from the frontend GET API (Gutendex / Project Gutenberg)
  /// without calling the backend.
  Future<List<Book>> fetchBooks({String query = '', String? category}) async {
    final cleanQuery = query.trim().toLowerCase();
    final cleanCategory = category?.trim().toLowerCase();

    // 1. Search or category filter queries
    if (cleanQuery.isNotEmpty || (cleanCategory != null && cleanCategory.isNotEmpty)) {
      try {
        final uri = Uri.parse(gutendexBaseUrl).replace(
          queryParameters: {
            'languages': 'en',
            if (cleanQuery.isNotEmpty) 'search': cleanQuery,
            if (cleanCategory != null && cleanCategory.isNotEmpty) 'topic': cleanCategory,
          },
        );

        final resp = await http.get(uri).timeout(const Duration(seconds: 12));
        if (resp.statusCode == 200) {
          final data = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
          final results = data['results'] as List? ?? [];
          final books = results
              .map((item) => Book.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList();

          if (books.isNotEmpty) {
            for (final b in books) {
              if (!_allCachedBooks.any((c) => c.id == b.id)) {
                _allCachedBooks.add(b);
              }
            }
            return books;
          }
        }
      } catch (_) {
        // Query request timed out or failed, fall back to local filtering
      }

      // Filter in-memory cached books
      if (_allCachedBooks.isNotEmpty) {
        final filtered = _allCachedBooks.where((b) {
          final matchesQuery = cleanQuery.isEmpty ||
              b.title.toLowerCase().contains(cleanQuery) ||
              b.authorName.toLowerCase().contains(cleanQuery);
          final matchesCat = cleanCategory == null ||
              cleanCategory.isEmpty ||
              (b.category != null && b.category!.toLowerCase().contains(cleanCategory));
          return matchesQuery && matchesCat;
        }).toList();
        if (filtered.isNotEmpty) return filtered;
      }
    }

    // 2. Fetch full catalog of books from Gutendex GET API (multiple pages concurrently)
    final List<Book> fetchedBooks = [];
    final Set<int> seenIds = {};

    try {
      final pageUrls = [
        Uri.parse('$gutendexBaseUrl?languages=en&page=1'),
        Uri.parse('$gutendexBaseUrl?languages=en&page=2'),
        Uri.parse('$gutendexBaseUrl?languages=en&page=3'),
      ];

      final responses = await Future.wait(
        pageUrls.map(
          (u) => http
              .get(u)
              .timeout(const Duration(seconds: 12))
              .catchError((_) => http.Response('{}', 500)),
        ),
      );

      for (final resp in responses) {
        if (resp.statusCode == 200) {
          final data = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
          final results = data['results'] as List? ?? [];
          for (final item in results) {
            final b = Book.fromJson(Map<String, dynamic>.from(item as Map));
            if (!seenIds.contains(b.id)) {
              seenIds.add(b.id);
              fetchedBooks.add(b);
            }
          }
        }
      }
    } catch (_) {
      // API temporarily slow, fall back to cached or curated catalog
    }

    if (fetchedBooks.isNotEmpty) {
      _allCachedBooks.clear();
      _allCachedBooks.addAll(fetchedBooks);
      return fetchedBooks;
    }

    // 3. Fallback: cached catalog or curated classics if offline
    if (_allCachedBooks.isNotEmpty) {
      return _allCachedBooks;
    }

    return _getCuratedFallbackBooks();
  }

  static List<Book> _getCuratedFallbackBooks() {
    return const [
      Book(
        id: 84,
        title: 'Frankenstein; Or, The Modern Prometheus',
        authors: ['Mary Wollstonecraft Shelley'],
        coverUrl: 'https://www.gutenberg.org/cache/epub/84/pg84.cover.medium.jpg',
        downloadCount: 98250,
        category: 'Science',
        description: 'The story of Victor Frankenstein and his monstrous creation.',
        formats: {
          'text/plain; charset=utf-8': 'https://www.gutenberg.org/cache/epub/84/pg84.txt',
          'image/jpeg': 'https://www.gutenberg.org/cache/epub/84/pg84.cover.medium.jpg',
        },
      ),
      Book(
        id: 1342,
        title: 'Pride and Prejudice',
        authors: ['Jane Austen'],
        coverUrl: 'https://www.gutenberg.org/cache/epub/1342/pg1342.cover.medium.jpg',
        downloadCount: 75320,
        category: 'Romance',
        description: 'A classic romantic novel of manners written by Jane Austen in 1813.',
        formats: {
          'text/plain; charset=utf-8': 'https://www.gutenberg.org/cache/epub/1342/pg1342.txt',
          'image/jpeg': 'https://www.gutenberg.org/cache/epub/1342/pg1342.cover.medium.jpg',
        },
      ),
      Book(
        id: 64317,
        title: 'The Great Gatsby',
        authors: ['F. Scott Fitzgerald'],
        coverUrl: 'https://www.gutenberg.org/cache/epub/64317/pg64317.cover.medium.jpg',
        downloadCount: 61200,
        category: 'Fiction',
        description: 'The story of Jay Gatsby and his pursuit of Daisy Buchanan in the Roaring Twenties.',
        formats: {
          'text/plain; charset=utf-8': 'https://www.gutenberg.org/cache/epub/64317/pg64317.txt',
          'image/jpeg': 'https://www.gutenberg.org/cache/epub/64317/pg64317.cover.medium.jpg',
        },
      ),
      Book(
        id: 11,
        title: "Alice's Adventures in Wonderland",
        authors: ['Lewis Carroll'],
        coverUrl: 'https://www.gutenberg.org/cache/epub/11/pg11.cover.medium.jpg',
        downloadCount: 45100,
        category: 'Fantasy',
        description: "Alice's descent into a subterranean fantasy world of curious creatures.",
        formats: {
          'text/plain; charset=utf-8': 'https://www.gutenberg.org/cache/epub/11/pg11.txt',
          'image/jpeg': 'https://www.gutenberg.org/cache/epub/11/pg11.cover.medium.jpg',
        },
      ),
      Book(
        id: 1661,
        title: 'The Adventures of Sherlock Holmes',
        authors: ['Arthur Conan Doyle'],
        coverUrl: 'https://www.gutenberg.org/cache/epub/1661/pg1661.cover.medium.jpg',
        downloadCount: 89400,
        category: 'Adventure',
        description: 'A collection of twelve short stories featuring Sherlock Holmes.',
        formats: {
          'text/plain; charset=utf-8': 'https://www.gutenberg.org/cache/epub/1661/pg1661.txt',
          'image/jpeg': 'https://www.gutenberg.org/cache/epub/1661/pg1661.cover.medium.jpg',
        },
      ),
      Book(
        id: 2701,
        title: 'Moby Dick; Or, The Whale',
        authors: ['Herman Melville'],
        coverUrl: 'https://www.gutenberg.org/cache/epub/2701/pg2701.cover.medium.jpg',
        downloadCount: 65400,
        category: 'Adventure',
        description: 'The sailor Ishmael and Captain Ahab obsessively pursue the great white whale.',
        formats: {
          'text/plain; charset=utf-8': 'https://www.gutenberg.org/cache/epub/2701/pg2701.txt',
          'image/jpeg': 'https://www.gutenberg.org/cache/epub/2701/pg2701.cover.medium.jpg',
        },
      ),
      Book(
        id: 345,
        title: 'Dracula',
        authors: ['Bram Stoker'],
        coverUrl: 'https://www.gutenberg.org/cache/epub/345/pg345.cover.medium.jpg',
        downloadCount: 58200,
        category: 'Fiction',
        description: 'The classic Gothic vampire novel introducing Count Dracula.',
        formats: {
          'text/plain; charset=utf-8': 'https://www.gutenberg.org/cache/epub/345/pg345.txt',
          'image/jpeg': 'https://www.gutenberg.org/cache/epub/345/pg345.cover.medium.jpg',
        },
      ),
      Book(
        id: 174,
        title: 'The Picture of Dorian Gray',
        authors: ['Oscar Wilde'],
        coverUrl: 'https://www.gutenberg.org/cache/epub/174/pg174.cover.medium.jpg',
        downloadCount: 52100,
        category: 'Fiction',
        description: 'The story of a young man whose portrait ages while he remains youthful.',
        formats: {
          'text/plain; charset=utf-8': 'https://www.gutenberg.org/cache/epub/174/pg174.txt',
          'image/jpeg': 'https://www.gutenberg.org/cache/epub/174/pg174.cover.medium.jpg',
        },
      ),
      Book(
        id: 1260,
        title: 'Jane Eyre: An Autobiography',
        authors: ['Charlotte Brontë'],
        coverUrl: 'https://www.gutenberg.org/cache/epub/1260/pg1260.cover.medium.jpg',
        downloadCount: 47900,
        category: 'Romance',
        description: 'The emotional growth and romance of orphan Jane Eyre at Thornfield Hall.',
        formats: {
          'text/plain; charset=utf-8': 'https://www.gutenberg.org/cache/epub/1260/pg1260.txt',
          'image/jpeg': 'https://www.gutenberg.org/cache/epub/1260/pg1260.cover.medium.jpg',
        },
      ),
      Book(
        id: 98,
        title: 'A Tale of Two Cities',
        authors: ['Charles Dickens'],
        coverUrl: 'https://www.gutenberg.org/cache/epub/98/pg98.cover.medium.jpg',
        downloadCount: 43200,
        category: 'History',
        description: 'A historical novel set in London and Paris during the French Revolution.',
        formats: {
          'text/plain; charset=utf-8': 'https://www.gutenberg.org/cache/epub/98/pg98.txt',
          'image/jpeg': 'https://www.gutenberg.org/cache/epub/98/pg98.cover.medium.jpg',
        },
      ),
      Book(
        id: 1513,
        title: 'Romeo and Juliet',
        authors: ['William Shakespeare'],
        coverUrl: 'https://www.gutenberg.org/cache/epub/1513/pg1513.cover.medium.jpg',
        downloadCount: 56700,
        category: 'Romance',
        description: 'The classic tragedy of two star-crossed lovers in Verona.',
        formats: {
          'text/plain; charset=utf-8': 'https://www.gutenberg.org/cache/epub/1513/pg1513.txt',
          'image/jpeg': 'https://www.gutenberg.org/cache/epub/1513/pg1513.cover.medium.jpg',
        },
      ),
      Book(
        id: 2591,
        title: "Grimms' Fairy Tales",
        authors: ['Jacob Grimm', 'Wilhelm Grimm'],
        coverUrl: 'https://www.gutenberg.org/cache/epub/2591/pg2591.cover.medium.jpg',
        downloadCount: 39800,
        category: 'Fantasy',
        description: 'Classic folk and fairy tales collected by the Brothers Grimm.',
        formats: {
          'text/plain; charset=utf-8': 'https://www.gutenberg.org/cache/epub/2591/pg2591.txt',
          'image/jpeg': 'https://www.gutenberg.org/cache/epub/2591/pg2591.cover.medium.jpg',
        },
      ),
    ];
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

  /// Persists reading progress to backend PostgreSQL and reading_history
  Future<void> saveReadingProgress({
    required int bookId,
    required int page,
    required int totalPages,
    String? title,
    String? author,
    String? coverUrl,
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
              if (title != null && title.isNotEmpty) 'title': title,
              if (author != null && author.isNotEmpty) 'author': author,
              if (coverUrl != null && coverUrl.isNotEmpty) 'cover_url': coverUrl,
            }),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      // Progress saving operates in background, non-blocking
    }
  }

  /// Fetches the authenticated user's reading history
  Future<List<ReadingHistoryItem>> fetchReadingHistory() async {
    final token = AuthService().token;
    if (token == null || token.isEmpty) {
      return [];
    }

    final uri = Uri.parse('${ApiConstants.apiV1}/reading-history');
    final response = await http
        .get(uri, headers: AuthService().authHeaders)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is List) {
        return decoded
            .map<ReadingHistoryItem>((item) =>
                ReadingHistoryItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } else if (response.statusCode == 401) {
      throw Exception('Session expired. Please log in again.');
    } else {
      throw Exception('Failed to load reading history (HTTP ${response.statusCode}).');
    }
  }

  /// Deletes a specific book from the user's reading history
  Future<bool> deleteReadingHistoryItem(int bookId) async {
    final uri = Uri.parse('${ApiConstants.apiV1}/reading-history/$bookId');
    final response = await http
        .delete(uri, headers: AuthService().authHeaders)
        .timeout(const Duration(seconds: 10));
    return response.statusCode == 204 || response.statusCode == 200;
  }

  /// Clears all reading history for the current user
  Future<bool> clearReadingHistory() async {
    final uri = Uri.parse('${ApiConstants.apiV1}/reading-history');
    final response = await http
        .delete(uri, headers: AuthService().authHeaders)
        .timeout(const Duration(seconds: 10));
    return response.statusCode == 204 || response.statusCode == 200;
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
