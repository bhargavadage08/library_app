
import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../repo/book_repo.dart';
import 'book_read_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color backgroundColor = Color(0xFFF8F7FF);

  final BookRepository _repository = BookRepository();
  final TextEditingController _searchController =
      TextEditingController();

  late Future<List<Book>> _booksFuture;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _booksFuture = _repository.fetchBooks();
  }

  void _searchBooks(String value) {
    setState(() {
      _query = value.trim();
      _booksFuture = _repository.fetchBooks(query: _query);
    });
  }

  void _reloadBooks() {
    setState(() {
      _booksFuture = _repository.fetchBooks(query: _query);
    });
  }

  // Show book details popup
  void _showBookDetails(Book book) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          content: SizedBox(
            width: 320,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Book cover
                  SizedBox(
                    height: 175,
                    width: 140,
                    child: book.coverUrl != null &&
                            book.coverUrl!.startsWith('https://')
                        ? Image.network(
                            book.coverUrl!,
                            fit: BoxFit.contain,
                            webHtmlElementStrategy:
                                WebHtmlElementStrategy.prefer,
                            errorBuilder: (_, __, ___) =>
                                _coverPlaceholder(),
                          )
                        : _coverPlaceholder(),
                  ),

                  const SizedBox(height: 18),

                  // Title
                  Text(
                    book.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Author
                  Text(
                    'By ${book.authorName}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Download count
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0EDFF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${book.downloadCount} downloads',
                      style: const TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Read book button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(dialogContext);

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                BookReaderScreen(book: book),
                          ),
                        );
                      },
                      icon: const Icon(Icons.menu_book_rounded),
                      label: const Text(
                        'Read Book',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                    },
                    child: const Text(
                      'Close',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header and search
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // App header
                    Row(
                      children: [
                        Container(
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.menu_book_rounded,
                            color: primaryColor,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BookVerse',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Your next adventure awaits',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.auto_awesome_rounded,
                          color: primaryColor,
                          size: 27,
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Welcome text
                    const Text(
                      'Hello, Reader! ',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Discover your next favorite book.',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 22),

                    // Search books
                    TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: _searchBooks,
                      decoration: InputDecoration(
                        hintText: 'Search books or authors...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: primaryColor,
                        ),
                        suffixIcon: IconButton(
                          tooltip: 'Search',
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: () =>
                              _searchBooks(_searchController.text),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Featured banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF7669F8),
                            Color(0xFF9B8AFB),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'YOUR DIGITAL LIBRARY',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    letterSpacing: 1,
                                  ),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Explore thousands of books',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Find your next great read.',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 10),
                          Icon(
                            Icons.auto_stories_rounded,
                            color: Colors.white,
                            size: 65,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Books heading
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _query.isEmpty
                                ? 'Popular Books'
                                : 'Search Results',
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Refresh books',
                          onPressed: _reloadBooks,
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    const Text(
                      'Books from Project Gutenberg',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Fetch books from API
            FutureBuilder<List<Book>>(
              future: _booksFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: primaryColor,
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.wifi_off_rounded,
                              size: 55,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Could not load books',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Check your internet connection and try again.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _reloadBooks,
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final books = snapshot.data ?? [];

                if (books.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        'No books found. Try another search.',
                      ),
                    ),
                  );
                }

                // Book grid
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.58,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final book = books[index];

                        return InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => _showBookDetails(book),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: 0.04,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                // Cover image
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(12),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: book.coverUrl != null &&
                                              book.coverUrl!
                                                  .startsWith('https://')
                                          ? Image.network(
                                              book.coverUrl!,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              webHtmlElementStrategy:
                                                  WebHtmlElementStrategy
                                                      .prefer,
                                              loadingBuilder: (
                                                context,
                                                child,
                                                progress,
                                              ) {
                                                if (progress == null) {
                                                  return child;
                                                }

                                                return const Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: primaryColor,
                                                  ),
                                                );
                                              },
                                              errorBuilder: (
                                                context,
                                                error,
                                                stackTrace,
                                              ) {
                                                debugPrint(
                                                  'Cover error: $error',
                                                );
                                                return _coverPlaceholder();
                                              },
                                            )
                                          : _coverPlaceholder(),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 10),

                                // Book title
                                Text(
                                  book.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 5),

                                // Author name
                                Text(
                                  book.authorName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.black54,
                                  ),
                                ),

                                const SizedBox(height: 7),

                                // Download count
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.download_rounded,
                                      size: 15,
                                      color: primaryColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        '${book.downloadCount} downloads',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 4),

                                const Row(
                                  children: [
                                    Icon(
                                      Icons.touch_app_outlined,
                                      size: 14,
                                      color: primaryColor,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Tap to read',
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: books.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),

      // Bottom navigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category_outlined),
            label: 'Categories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border_rounded),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // Placeholder when a cover is missing or fails to load
  Widget _coverPlaceholder() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFE9E5FF),
      child: const Center(
        child: Icon(
          Icons.menu_book_rounded,
          size: 55,
          color: primaryColor,
        ),
      ),
    );
  }
}
