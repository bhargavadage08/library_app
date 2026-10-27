import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../repo/book_repo.dart';
import 'book_categories_page.dart';
import 'book_detail_screen.dart';
import 'login_page.dart';
import '../repo/auth_repo.dart';

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

  late Future<List<Book>> _booksFuture;
  String _query = '';
  int _currentIndex = 0;

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

  void _showProfileDialog() {
    final user = AuthService().currentUser;
    final isLoggedIn = AuthService().isAuthenticated;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title:   Row(
            children: [
              Icon(Icons.person_rounded, color: primaryColor),
              SizedBox(width: 10),
              Text('User Profile'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user?.fullName ?? 'Guest Reader',
                style:   TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
                SizedBox(height: 6),
              Text(
                user?.email ?? 'Not logged in (Guest)',
                style:   TextStyle(color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child:   Text('Close'),
            ),
            if (isLoggedIn)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  AuthService().logout();
                  Navigator.pop(dialogContext);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) =>   LoginPage()),
                  );
                },
                icon:   Icon(Icons.logout, size: 18),
                label:   Text('Log Out'),
              )
            else
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) =>   LoginPage()),
                  );
                },
                icon:   Icon(Icons.login, size: 18),
                label:   Text('Log In'),
              ),
          ],
        );
      },
    );
  }

  // Navigate to book details screen
  void _showBookDetails(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookDetailsScreen(book: book),
      ),
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
                      'Hello, Reader! ',
                      style: TextStyle(
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
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child:
                                        book.coverUrl != null &&
                                            book.coverUrl!.startsWith(
                                              'https://',
                                            )
                                        ? Image.network(
                                            book.coverUrl!,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            webHtmlElementStrategy:
                                                WebHtmlElementStrategy.prefer,
                                            loadingBuilder:
                                                (context, child, progress) {
                                                  if (progress == null) {
                                                    return child;
                                                  }

                                                  return Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: primaryColor,
                                                        ),
                                                  );
                                                },
                                            errorBuilder:
                                                (context, error, stackTrace) {
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
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 0) {
            if (_query.isNotEmpty) {
              _searchController.clear();
              _searchBooks('');
            }
          } else if (index == 1) {
            _openCategories();
          } else if (index == 2) {
            if (!AuthService().isAuthenticated) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                  content: Text('Please log in to view and sync your favorites!'),
                ),
              );
            } else {
              setState(() {
                _query = 'Favorites';
                _booksFuture = _repository.fetchFavorites();
              });
            }
          } else if (index == 3) {
            _showProfileDialog();
          }
        },
        items:   [
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
      color: Color(0xFFE9E5FF),
      child: Center(
        child: Icon(Icons.menu_book_rounded, size: 55, color: primaryColor),
      ),
    );
  }
}
