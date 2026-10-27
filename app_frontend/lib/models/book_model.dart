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
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    // Parse authors from Gutendex format or backend format
    List<String> parsedAuthors = [];
    if (json['authors'] is List) {
      parsedAuthors = (json['authors'] as List)
          .map((a) => a is Map ? (a['name']?.toString() ?? '') : a.toString())
          .where((a) => a.isNotEmpty)
          .toList();
    } else if (json['author_name'] != null &&
        json['author_name'].toString().isNotEmpty) {
      parsedAuthors = [json['author_name'].toString()];
    }

    final formatsJson = Map<String, dynamic>.from(json['formats'] ?? {});

    // Cover image can be from backend direct 'cover_url' or Gutendex formats
    String? cover = json['cover_url'] as String? ??
        formatsJson['image/jpeg'] as String? ??
        formatsJson['image/png'] as String?;

    return Book(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? 'Untitled',
      authors: parsedAuthors,
      coverUrl: cover,
      downloadCount: json['download_count'] as int? ?? 0,
      formats: formatsJson,
      category: json['category'] as String?,
      description: json['description'] as String?,
      isFavorite: json['is_favorite'] as bool? ?? false,
    );
  }

  String get authorName =>
      authors.isEmpty ? 'Unknown author' : authors.join(', ');

  String? get readingUrl =>
      formats['text/html'] as String? ??
      formats['text/plain; charset=utf-8'] as String? ??
      formats['text/plain'] as String?;
}
