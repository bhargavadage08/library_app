
class Book {
  final int id;
  final String title;
  final List<String> authors;
  final String? coverUrl;
  final int downloadCount;
  final Map<String, dynamic> formats;

  const Book({
    required this.id,
    required this.title,
    required this.authors,
    required this.coverUrl,
    required this.downloadCount,
    required this.formats,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    final authorsJson = json['authors'] as List? ?? [];

    final formatsJson =
        Map<String, dynamic>.from(json['formats'] ?? {});

    return Book(
      id: json['id'] as int,
      title: json['title'] as String? ?? 'Untitled',
      authors: authorsJson
          .map((author) =>
              author['name']?.toString() ?? 'Unknown author')
          .cast<String>()
          .toList(),
      coverUrl: formatsJson['image/jpeg'] as String?,
      downloadCount: json['download_count'] as int? ?? 0,
      formats: formatsJson,
    );
  }

  String get authorName =>
      authors.isEmpty ? 'Unknown author' : authors.join(', ');

  String? get readingUrl =>
      formats['text/html'] as String? ??
      formats['text/plain; charset=utf-8'] as String? ??
      formats['text/plain'] as String?;
}
