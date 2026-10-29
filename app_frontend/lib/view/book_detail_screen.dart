import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../models/reading_models.dart';
import '../repo/auth_repo.dart';
import '../repo/book_repo.dart';
import 'book_read_screen.dart';

class BookDetailsScreen extends StatefulWidget {
  final Book book;

  const BookDetailsScreen({
    super.key,
    required this.book,
  });

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  static const Color primaryColor = Color(0xFF5B4BDB);

  bool isFavorite = false;
  BookProgress? _savedProgress;

  @override
  void initState() {
    super.initState();
    isFavorite = widget.book.isFavorite;
    _checkReadingProgress();
  }

  Future<void> _checkReadingProgress() async {
    try {
      final prog = await BookRepository().getReadingProgress(widget.book.id);
      if (mounted) {
        setState(() {
          _savedProgress = prog;
        });
      }
    } catch (_) {}
  }

  String get authorName {
    return widget.book.authors.isEmpty
        ? 'Unknown Author'
        : widget.book.authors.join(', ');
  }

  String get description {
    if (widget.book.description != null &&
        widget.book.description!.trim().isNotEmpty) {
      return widget.book.description!.trim();
    }
    return 'Discover the world of ${widget.book.title}. '
        'Explore this book and enjoy your reading journey '
        'with our online book library.';
  }

  Future<void> _toggleFavorite() async {
    if (!AuthService().isAuthenticated) {
      setState(() {
        isFavorite = !isFavorite;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFavorite ? 'Added to favorites' : 'Removed from favorites',
          ),
        ),
      );
      return;
    }

    try {
      final fav = await BookRepository().toggleFavorite(widget.book.id);
      if (!mounted) return;
      setState(() {
        isFavorite = fav;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFavorite
                ? 'Saved "${widget.book.title}" to favorites!'
                : 'Removed from favorites',
          ),
        ),
      );
    } catch (_) {
      setState(() {
        isFavorite = !isFavorite;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F7FC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Book Details',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _toggleFavorite,
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : primaryColor,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),

            // Book cover
            Container(
              height: 270,
              width: 190,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                  ? Image.network(
                      book.coverUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.menu_book,
                          size: 90,
                          color: primaryColor,
                        );
                      },
                    )
                  : const Icon(
                      Icons.menu_book,
                      size: 90,
                      color: primaryColor,
                    ),
            ),

            const SizedBox(height: 26),

            // Book title
            Text(
              book.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),

            const SizedBox(height: 10),

            // Author
            Text(
              'by $authorName',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 20),

            // Book statistics
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: 18,
                horizontal: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem(
                    Icons.download_outlined,
                    'Downloads',
                    '${book.downloadCount}',
                  ),
                  Container(
                    height: 42,
                    width: 1,
                    color: Colors.grey.shade200,
                  ),
                  _statItem(
                    Icons.menu_book_outlined,
                    'Format',
                    'Digital',
                  ),
                  Container(
                    height: 42,
                    width: 1,
                    color: Colors.grey.shade200,
                  ),
                  _statItem(
                    Icons.bookmark_outline,
                    'Library',
                    'eBook',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 26),

            // Description
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'About this book',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                description,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                  height: 1.7,
                ),
              ),
            ),

            const SizedBox(height: 30),

            if (_savedProgress != null && _savedProgress!.currentPage > 1) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.history_edu_rounded, color: primaryColor, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Reading Progress',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: primaryColor,
                                ),
                              ),
                              Text(
                                '${_savedProgress!.percentage.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Saved at Page ${_savedProgress!.currentPage} of ${_savedProgress!.totalPages}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Read book button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookReaderScreen(
                        book: book,
                        initialPage: _savedProgress?.currentPage,
                      ),
                    ),
                  );
                  _checkReadingProgress();
                },
                icon: const Icon(Icons.menu_book),
                label: Text(
                  _savedProgress != null && _savedProgress!.currentPage > 1
                      ? 'Continue Reading (Page ${_savedProgress!.currentPage})'
                      : 'Read Book',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Favorite button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton.icon(
                onPressed: _toggleFavorite,
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                ),
                label: Text(
                  isFavorite ? 'Added to Favorites' : 'Add to Favorites',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: const BorderSide(color: primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _statItem(
    IconData icon,
    String label,
    String value,
  ) {
    return Column(
      children: [
        Icon(icon, color: primaryColor, size: 24),
        const SizedBox(height: 7),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
