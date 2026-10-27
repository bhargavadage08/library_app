class BookPage {
  final int bookId;
  final String title;
  final String author;
  final int page;
  final int pageSize;
  final int totalPages;
  final int totalCharacters;
  final String content;
  final bool hasPrev;
  final bool hasNext;
  final bool isAppGenerated;

  const BookPage({
    required this.bookId,
    required this.title,
    required this.author,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.totalCharacters,
    required this.content,
    required this.hasPrev,
    required this.hasNext,
    this.isAppGenerated = true,
  });

  factory BookPage.fromJson(Map<String, dynamic> json) {
    return BookPage(
      bookId: json['book_id'] as int? ?? 0,
      title: json['title'] as String? ?? 'Untitled',
      author: json['author'] as String? ?? 'Unknown Author',
      page: json['page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? 2500,
      totalPages: json['total_pages'] as int? ?? 1,
      totalCharacters: json['total_characters'] as int? ?? 0,
      content: json['content'] as String? ?? '',
      hasPrev: json['has_prev'] as bool? ?? false,
      hasNext: json['has_next'] as bool? ?? false,
      isAppGenerated: json['is_app_generated'] as bool? ?? true,
    );
  }
}

class BookProgress {
  final int bookId;
  final int currentPage;
  final int totalPages;
  final double percentage;
  final DateTime? updatedAt;

  const BookProgress({
    required this.bookId,
    required this.currentPage,
    required this.totalPages,
    required this.percentage,
    this.updatedAt,
  });

  factory BookProgress.fromJson(Map<String, dynamic> json) {
    final updatedStr = json['updated_at'] as String?;
    return BookProgress(
      bookId: json['book_id'] as int? ?? 0,
      currentPage: json['current_page'] as int? ?? 1,
      totalPages: json['total_pages'] as int? ?? 1,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      updatedAt: updatedStr != null ? DateTime.tryParse(updatedStr) : null,
    );
  }
}
