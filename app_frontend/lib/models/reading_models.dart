import 'book_model.dart';

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

class ReadingHistoryItem {
  final int id;
  final int userId;
  final int bookId;
  final String title;
  final String? author;
  final String? coverUrl;
  final int currentPage;
  final int? totalPages;
  final int progressPercent;
  final DateTime? createdAt;
  final DateTime? lastReadAt;

  const ReadingHistoryItem({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.title,
    this.author,
    this.coverUrl,
    required this.currentPage,
    this.totalPages,
    required this.progressPercent,
    this.createdAt,
    this.lastReadAt,
  });

  factory ReadingHistoryItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    return ReadingHistoryItem(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      bookId: json['book_id'] as int? ?? 0,
      title: json['title'] as String? ?? 'Untitled Book',
      author: json['author'] as String?,
      coverUrl: json['cover_url'] as String?,
      currentPage: json['current_page'] as int? ?? 1,
      totalPages: json['total_pages'] as int?,
      progressPercent: json['progress_percent'] as int? ?? 0,
      createdAt: parseDate(json['created_at']),
      lastReadAt: parseDate(json['last_read_at']),
    );
  }

  double get progressFraction {
    if (progressPercent > 0) {
      return (progressPercent / 100.0).clamp(0.0, 1.0);
    }
    if (totalPages != null && totalPages! > 0) {
      return (currentPage / totalPages!).clamp(0.0, 1.0);
    }
    return 0.0;
  }

  String get displayAuthor =>
      (author != null && author!.trim().isNotEmpty)
          ? author!.trim()
          : 'Unknown Author';

  String get pageProgressText {
    if (totalPages != null && totalPages! > 0) {
      return 'Page $currentPage of $totalPages';
    }
    return 'Page $currentPage';
  }

  String get lastReadFormatted {
    if (lastReadAt == null) return 'Recently';

    final localDate = lastReadAt!.toLocal();
    final now = DateTime.now();
    final diff = now.difference(localDate);

    if (diff.inMinutes < 2) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24 && localDate.day == now.day) {
      return 'Today at ${localDate.hour.toString().padLeft(2, '0')}:${localDate.minute.toString().padLeft(2, '0')}';
    }

    final yesterday = now.subtract(const Duration(days: 1));
    if (localDate.day == yesterday.day &&
        localDate.month == yesterday.month &&
        localDate.year == yesterday.year) {
      return 'Yesterday';
    }

    if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    }

    return '${localDate.day.toString().padLeft(2, '0')}/${localDate.month.toString().padLeft(2, '0')}/${localDate.year}';
  }

  bool get isCompleted =>
      progressPercent >= 100 ||
      (totalPages != null && totalPages! > 0 && currentPage >= totalPages!);

  Book toBook() {
    return Book(
      id: bookId,
      title: title,
      authors: author != null && author!.trim().isNotEmpty
          ? [author!.trim()]
          : ['Unknown Author'],
      coverUrl: coverUrl,
      downloadCount: 0,
      formats: {},
    );
  }
}


