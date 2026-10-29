import 'package:app_frontend/view/profile_screen.dart';
import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../models/reading_models.dart';
import '../repo/book_repo.dart';
import 'book_categories_page.dart';
import 'book_detail_screen.dart';
import 'book_read_screen.dart';
import '../constant/color_const.dart';
import '../repo/auth_repo.dart';
import 'favorites_screen.dart';
import 'reading_history_screen.dart';

class HomePage extends StatefulWidget {
  final String? initialCategory;
  const HomePage({super.key, this.initialCategory});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color backgroundColor = Color(0xFFF8F7FF);

  final BookRepository _repository = BookRepository();
  final TextEditingController _searchController = TextEditingController();
  final List<Book> favoriteBooks = [];

  late Future<List<Book>> _booksFuture;
  String _query = '';
  int _currentIndex = 0;
  List<ReadingHistoryItem> _readingHistory = [];

  bool _isFavorite(Book book) {
    return favoriteBooks.any((item) => item.id == book.id);
  }

  void _toggleFavorite(Book book) {
    setState(() {
      if (_isFavorite(book)) {
        favoriteBooks.removeWhere((item) => item.id == book.id);
      } else {
        favoriteBooks.add(book);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isFavorite(book) ? 'Added to Favorites' : 'Removed from Favorites',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null &&
        widget.initialCategory!.trim().isNotEmpty) {
      _query = widget.initialCategory!.trim();
      _searchController.text = _query;
      _booksFuture = _repository.fetchBooks(query: _query);
    } else {
      _booksFuture = _repository.fetchBooks();
    }
    _loadRecentHistory();
  }

  Future<void> _loadRecentHistory() async {
    if (!AuthService().isAuthenticated) {
      if (mounted && _readingHistory.isNotEmpty) {
        setState(() {
          _readingHistory = [];
        });
      }
      return;
    }
    try {
      final items = await _repository.fetchReadingHistory();
      if (mounted) {
        setState(() {
          _readingHistory = items;
        });
      }
    } catch (_) {}
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
    _loadRecentHistory();
  }

  Future<void> _openCategories() async {
    final selectedCategory = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BookCategoriesPage()),
    );
    if (selectedCategory != null && selectedCategory.trim().isNotEmpty) {
      _searchBooks(selectedCategory.trim());
      _searchController.text = selectedCategory.trim();
    }
  }

  Widget _coverPlaceholer() {
    return Container(
      width: double.infinity,
      color: Color(0xFFE9E5FF),
      child: Center(
        child: Icon(Icons.menu_book_rounded, size: 55, color: primaryColor),
      ),
    );
  }


  // Navigate to book details screen
  void _showBookDetails(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookDetailsScreen(book: book)),
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
              padding: EdgeInsets.all(20),
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
                          child: Icon(
                            Icons.menu_book_rounded,
                            color: primaryColor,
                            size: 28,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
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
                        Icon(
                          Icons.auto_awesome_rounded,
                          color: primaryColor,
                          size: 27,
                        ),
                      ],
                    ),

                    SizedBox(height: 28),

                    // Welcome text
                    Text(
                      'Hello, ${AuthService().currentUser?.fullName ?? 'Reader'}! ',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 8),

                    Text(
                      'Discover your next favorite book.',
                      style: TextStyle(color: Colors.black54, fontSize: 14),
                    ),

                    SizedBox(height: 22),

                    // Search books
                    TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: _searchBooks,
                      decoration: InputDecoration(
                        hintText: 'Search books or authors...',
                        prefixIcon: Icon(Icons.search, color: primaryColor),
                        suffixIcon: IconButton(
                          tooltip: 'Search',
                          icon: Icon(Icons.arrow_forward),
                          onPressed: () => _searchBooks(_searchController.text),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    SizedBox(height: 24),

                    // Featured banner
                    GestureDetector(
                      onTap: _openCategories,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF7669F8), Color(0xFF9B8AFB)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                    ),

                    SizedBox(height: 28),

                    // Continue Reading Section (as per authenticated user)
                    if (_readingHistory.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.history_rounded,
                                color: primaryColor,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Continue Reading',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF24213A),
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ReadingHistoryScreen(),
                                ),
                              ).then((_) => _loadRecentHistory());
                            },
                            child: const Text('See All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 135,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _readingHistory.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final item = _readingHistory[index];
                            final progress = item.progressFraction;
                            final percentInt = (progress * 100).round();

                            return Container(
                              width: 270,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: InkWell(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BookReaderScreen(
                                        book: item.toBook(),
                                        initialPage: item.currentPage,
                                      ),
                                    ),
                                  );
                                  _loadRecentHistory();
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: SizedBox(
                                        width: 65,
                                        height: 95,
                                        child:
                                            item.coverUrl != null &&
                                                item.coverUrl!.isNotEmpty
                                            ? Image.network(
                                                item.coverUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => _coverPlaceholer(),
                                              )
                                            : _coverPlaceholer(),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            item.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: Color(0xFF24213A),
                                              height: 1.2,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item.displayAuthor,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 11,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                item.pageProgressText,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              Text(
                                                '$percentInt%',
                                                style: const TextStyle(
                                                  color: primaryColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            child: LinearProgressIndicator(
                                              value: progress,
                                              minHeight: 5,
                                              backgroundColor: const Color(
                                                0xFFECEBFA,
                                              ),
                                              valueColor:
                                                  const AlwaysStoppedAnimation<
                                                    Color
                                                  >(primaryColor),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 22),
                    ],

                    // Books heading
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _query.isEmpty ? 'Popular Books' : 'Search Results',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Refresh books',
                          onPressed: _reloadBooks,
                          icon: Icon(Icons.refresh),
                        ),
                      ],
                    ),

                    SizedBox(height: 4),

                    Text(
                      'Books from Project Gutenberg',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),

                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Fetch books from API
            FutureBuilder<List<Book>>(
              future: _booksFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.wifi_off_rounded,
                              size: 55,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Could not load books',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Check your internet connection and try again.',
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _reloadBooks,
                              child: Text('Try Again'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final books = snapshot.data ?? [];

                if (books.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text('No books found. Try another search.'),
                    ),
                  );
                }

                // Book grid
                return SliverPadding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.58,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final book = books[index];

                      return InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => _showBookDetails(book),
                        child: Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Cover image

                              Expanded(
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child:
                                            (book.coverUrl != null &&
                                                book.coverUrl!
                                                    .trim()
                                                    .isNotEmpty)
                                            ? Image.network(
                                                book.coverUrl!,
                                                width: double.infinity,
                                                height: double.infinity,
                                                fit: BoxFit.cover,
                                                webHtmlElementStrategy:
                                                    WebHtmlElementStrategy
                                                        .prefer,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) {
                                                      debugPrint(
                                                        'Cover failed: ${book.coverUrl} - $error',
                                                      );
                                                      return _coverPlaceholder();
                                                    },
                                              )
                                            : _coverPlaceholder(),
                                      ),
                                    ),

                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: Material(
                                        color: Colors.white,
                                        shape: const CircleBorder(),
                                        child: IconButton(
                                          tooltip: 'Add or remove favorite',
                                          visualDensity: VisualDensity.compact,
                                          icon: Icon(
                                            _isFavorite(book)
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color: _isFavorite(book)
                                                ? Colors.red
                                                : Colors.grey,
                                          ),
                                          onPressed: () =>
                                              _toggleFavorite(book),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 10),

                              // Book title
                              Text(
                                book.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              SizedBox(height: 5),

                              // Author name
                              Text(
                                book.authorName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.black54,
                                ),
                              ),

                              SizedBox(height: 7),

                              // Download count
                              Row(
                                children: [
                                  Icon(
                                    Icons.download_rounded,
                                    size: 15,
                                    color: primaryColor,
                                  ),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${book.downloadCount} downloads',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 10),
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 4),

                              Row(
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
                    }, childCount: books.length),
                  ),
                );
              },
            ),
          ],
        ),
      ),

      // Bottom navigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: AppColor.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,

        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });

          if (index == 0) {
            // Home
            if (_query.isNotEmpty) {
              _searchController.clear();
              _searchBooks('');
            }
          } else if (index == 1) {
            // Categories
            _openCategories();
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    FavoritesScreen(favoriteBook: favoriteBooks),
              ),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfileScreen()),
            );
          }
        },

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

  Widget _coverPlaceholder() {
    return Container(
      color: const Color(0xFFECEBFA),
      child: const Center(
        child: Icon(Icons.menu_book_rounded, size: 32, color: primaryColor),
      ),
    );
  }
}
