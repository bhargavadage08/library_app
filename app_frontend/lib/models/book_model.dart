class Book {
  final int id;
  final String title;
  final List<String> authors;
  final String? coverUrl;
  final int downloadCount;
  final Map<String, dynamic> formats;
  final String? category;
  final String? description;
  final bool isFavorite;

  // Gutenberg category information
  final List<String> subjects;
  final List<String> bookshelves;

  const Book({
    required this.id,
    required this.title,
    required this.authors,
    required this.coverUrl,
    required this.downloadCount,
    required this.formats,
    this.category,
    this.description,
    this.isFavorite = false,
    this.subjects = const [],
    this.bookshelves = const [],
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    // Parse authors
    List<String> parsedAuthors = [];

    if (json['authors'] is List) {
      parsedAuthors = (json['authors'] as List)
          .map((a) => a is Map ? (a['name']?.toString() ?? '') : a.toString())
          .where((a) => a.isNotEmpty)
          .toList();
    } else if (json['author_name'] != null) {
      parsedAuthors = [json['author_name'].toString()];
    }

    // Parse subjects
    final parsedSubjects = (json['subjects'] as List? ?? [])
        .map((item) => item.toString())
        .toList();

    // Parse bookshelves
    final parsedBookshelves = (json['bookshelves'] as List? ?? [])
        .map((item) => item.toString())
        .toList();

    // Parse formats
    final formatsJson = Map<String, dynamic>.from(
      json['formats'] is Map ? json['formats'] : {},
    );

    // Get cover
    final cover =
        json['cover_url'] as String? ??
        formatsJson['image/jpeg'] as String? ??
        formatsJson['image/png'] as String?;

    // Determine category
    final category =
        json['category']?.toString() ??
        _detectCategory(parsedSubjects, parsedBookshelves);

    return Book(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? 'Untitled',
      authors: parsedAuthors,
      coverUrl: cover,
      downloadCount: (json['download_count'] as num?)?.toInt() ?? 0,
      formats: formatsJson,
      category: category,
      description: json['description']?.toString(),
      isFavorite: json['is_favorite'] as bool? ?? false,
      subjects: parsedSubjects,
      bookshelves: parsedBookshelves,
    );
  }

  static String? _detectCategory(
    List<String> subjects,
    List<String> bookshelves,
  ) {
    final text = [...subjects, ...bookshelves].join(' ').toLowerCase();

    // Check specific categories before general fiction.
    if (text.contains('romance') || text.contains('love stories')) {
      return 'Romance';
    }

    if (text.contains('fantasy') || text.contains('fairy tales')) {
      return 'Fantasy';
    }

    if (text.contains('adventure')) {
      return 'Adventure';
    }

    if (text.contains('biography') || text.contains('autobiography')) {
      return 'Biography';
    }

    if (text.contains('education')) {
      return 'Education';
    }

    if (text.contains('science fiction') ||
        text.contains('natural science') ||
        text.contains('science')) {
      return 'Science';
    }

    if (text.contains('history')) {
      return 'History';
    }

    if (text.contains('fiction') || text.contains('novels')) {
      return 'Fiction';
    }

    return null;
  }

  String get authorName =>
      authors.isEmpty ? 'Unknown author' : authors.join(', ');

  String? get readingUrl =>
      formats['text/html'] as String? ??
      formats['text/plain; charset=utf-8'] as String? ??
      formats['text/plain'] as String?;
}
