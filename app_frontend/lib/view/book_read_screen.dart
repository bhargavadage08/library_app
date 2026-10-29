import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../models/reading_models.dart';
import '../repo/book_repo.dart';

enum ReaderTheme { warm, light, dark }

class BookReaderScreen extends StatefulWidget {
  final Book book;
  final int? initialPage;

  const BookReaderScreen({
    super.key,
    required this.book,
    this.initialPage,
  });

  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen> {
  final BookRepository _repository = BookRepository();
  final ScrollController _scrollController = ScrollController();

  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoading = true;
  String? _errorMessage;
  BookPage? _pageData;
  double _fontSize = 17;
  ReaderTheme _readerTheme = ReaderTheme.warm;

  Color get _backgroundColor {
    switch (_readerTheme) {
      case ReaderTheme.warm:
        return const Color(0xFFFFFCF5);
      case ReaderTheme.light:
        return const Color(0xFFFFFFFF);
      case ReaderTheme.dark:
        return const Color(0xFF1E1E2E);
    }
  }

  Color get _textColor {
    switch (_readerTheme) {
      case ReaderTheme.warm:
        return const Color(0xFF2B2B2B);
      case ReaderTheme.light:
        return const Color(0xFF1A1A1A);
      case ReaderTheme.dark:
        return const Color(0xFFE2E2F0);
    }
  }

  Color get _headerColor {
    switch (_readerTheme) {
      case ReaderTheme.warm:
        return const Color(0xFF2D232E);
      case ReaderTheme.light:
        return const Color(0xFF111111);
      case ReaderTheme.dark:
        return Colors.white;
    }
  }

  @override
  void initState() {
    super.initState();
    _initReadingState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Restores saved reading progress from backend and loads the page
  Future<void> _initReadingState() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (widget.initialPage != null && widget.initialPage! >= 1) {
      _currentPage = widget.initialPage!;
    } else {
      try {
        final savedProgress = await _repository.getReadingProgress(
          widget.book.id,
        );
        if (savedProgress != null && savedProgress.currentPage > 1) {
          _currentPage = savedProgress.currentPage;
        }
      } catch (_) {
        // Fallback to page 1
      }
    }

    await _loadPage(_currentPage);
  }

  /// Fetches a specific page and saves the reading progress
  Future<void> _loadPage(int targetPage) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final pageData = await _repository.fetchBookPage(
        bookId: widget.book.id,
        page: targetPage,
        pageSize: 2500,
        book: widget.book,
      );

      if (!mounted) return;

      setState(() {
        _pageData = pageData;
        _currentPage = pageData.page;
        _totalPages = pageData.totalPages;
        _isLoading = false;
      });

      // Scroll smoothly to top of the page
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }

      // Persist progress asynchronously with book metadata
      _repository.saveReadingProgress(
        bookId: widget.book.id,
        page: _currentPage,
        totalPages: _totalPages,
        title: widget.book.title,
        author: widget.book.authorName,
        coverUrl: widget.book.coverUrl,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 1 && !_isLoading) {
      _loadPage(_currentPage - 1);
    }
  }

  void _goToNextPage() {
    if (_currentPage < _totalPages && !_isLoading) {
      _loadPage(_currentPage + 1);
    }
  }

  void _showJumpToPageDialog() {
    if (_totalPages <= 1) return;
    int target = _currentPage;
    final controller = TextEditingController(text: _currentPage.toString());

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.auto_stories, color: Color(0xFF6C63FF)),
                  SizedBox(width: 10),
                  Text('Jump to Page'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Page $target of $_totalPages',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6C63FF),
                    ),
                  ),
                  SizedBox(height: 12),
                  Slider(
                    value: target.toDouble().clamp(1.0, _totalPages.toDouble()),
                    min: 1.0,
                    max: _totalPages.toDouble(),
                    divisions: _totalPages > 1 ? _totalPages - 1 : 1,
                    activeColor: Color(0xFF6C63FF),
                    onChanged: (val) {
                      setDialogState(() {
                        target = val.round();
                        controller.text = target.toString();
                      });
                    },
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Enter page number (1 - $_totalPages)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    onChanged: (val) {
                      final parsed = int.tryParse(val.trim());
                      if (parsed != null &&
                          parsed >= 1 &&
                          parsed <= _totalPages) {
                        setDialogState(() {
                          target = parsed;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    if (target != _currentPage) {
                      _loadPage(target);
                    }
                  },
                  child: Text('Go'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _cycleTheme() {
    setState(() {
      switch (_readerTheme) {
        case ReaderTheme.warm:
          _readerTheme = ReaderTheme.light;
          break;
        case ReaderTheme.light:
          _readerTheme = ReaderTheme.dark;
          break;
        case ReaderTheme.dark:
          _readerTheme = ReaderTheme.warm;
          break;
      }
    });
  }

  IconData get _themeIcon {
    switch (_readerTheme) {
      case ReaderTheme.warm:
        return Icons.wb_sunny_outlined;
      case ReaderTheme.light:
        return Icons.light_mode_outlined;
      case ReaderTheme.dark:
        return Icons.dark_mode_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double readPercentage = _totalPages > 0
        ? (_currentPage / _totalPages) * 100
        : 0.0;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          tooltip: 'Back to Library',
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.book.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.book.authorName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Jump to page',
            icon: Icon(Icons.swap_calls_rounded),
            onPressed: _totalPages > 1 ? _showJumpToPageDialog : null,
          ),
          IconButton(
            tooltip: 'Reading Theme (Warm / Light / Dark)',
            icon: Icon(_themeIcon),
            onPressed: _cycleTheme,
          ),
          IconButton(
            tooltip: 'Decrease text size',
            onPressed: () {
              setState(() {
                if (_fontSize > 12) _fontSize -= 1;
              });
            },
            icon: Icon(Icons.text_decrease),
          ),
          IconButton(
            tooltip: 'Increase text size',
            onPressed: () {
              setState(() {
                if (_fontSize < 30) _fontSize += 1;
              });
            },
            icon: Icon(Icons.text_increase),
          ),
          Container(
            margin: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: Color(0x33FFFFFF),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              '${readPercentage.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomPaginationBar(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF6C63FF), strokeWidth: 3),
            SizedBox(height: 18),
            Text(
              'Loading page $_currentPage of $_totalPages...',
              style: TextStyle(
                fontSize: 15,
                color: _textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Loading authentic complete book text',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.menu_book_outlined,
                size: 56,
                color: Color(0xFF6C63FF),
              ),
              SizedBox(height: 16),
              Text(
                'Unable to Load Page',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF25213B),
                ),
              ),
              SizedBox(height: 10),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => _loadPage(_currentPage),
                icon: Icon(Icons.refresh, size: 18),
                label: Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final pageContent = _pageData?.content ?? '';

    return SelectionArea(
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header on First Page
                if (_currentPage == 1) ...[
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.auto_stories_rounded,
                          size: 44,
                          color: Color(0xFF6C63FF),
                        ),
                        SizedBox(height: 12),
                        Text(
                          widget.book.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _headerColor,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'by ${widget.book.authorName}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: _readerTheme == ReaderTheme.dark
                                ? Colors.white70
                                : Colors.black54,
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Color(0x1F6C63FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Complete Edition • Full Text',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6C63FF),
                            ),
                          ),
                        ),
                        SizedBox(height: 18),
                        Divider(
                          color: _readerTheme == ReaderTheme.dark
                              ? Colors.white24
                              : Colors.black12,
                        ),
                        SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],

                // Actual Authentic Book Page Content
                Text(
                  pageContent,
                  style: TextStyle(
                    fontSize: _fontSize,
                    height: 1.85,
                    letterSpacing: 0.2,
                    color: _textColor,
                    fontFamily: 'serif',
                  ),
                ),

                SizedBox(height: 36),
                Center(
                  child: Text(
                    'Page $_currentPage of $_totalPages • Complete Novel Text',
                    style: TextStyle(
                      fontSize: 12,
                      color: _readerTheme == ReaderTheme.dark
                          ? Colors.white54
                          : Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPaginationBar() {
    final bool canGoPrev = _currentPage > 1 && !_isLoading;
    final bool canGoNext = _currentPage < _totalPages && !_isLoading;
    final double progressVal = _totalPages > 0
        ? (_currentPage / _totalPages).clamp(0.0, 1.0)
        : 0.0;

    final isDark = _readerTheme == ReaderTheme.dark;
    final barBg = isDark ? const Color(0xFF28283C) : const Color(0xFFFFFDF9);
    final borderColor = isDark ? Colors.white12 : const Color(0x409E9E9E);
    final centerTextColor = isDark ? Colors.white : const Color(0xFF333333);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: barBg,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Linear progress indicator
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progressVal,
                backgroundColor: isDark ? Colors.white12 : Color(0xFFE9E5DD),
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
                minHeight: 4,
              ),
            ),
            SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Previous Page Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canGoPrev
                        ? Color(0xFF6C63FF)
                        : (isDark ? Colors.white12 : Colors.grey.shade300),
                    foregroundColor: canGoPrev
                        ? Colors.white
                        : (isDark ? Colors.white38 : Colors.grey.shade600),
                    elevation: canGoPrev ? 1 : 0,
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: canGoPrev ? _goToPreviousPage : null,
                  icon: Icon(Icons.chevron_left_rounded, size: 20),
                  label: Text(
                    'Previous',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),

                // Center page indicator with tap to jump
                InkWell(
                  onTap: _totalPages > 1 ? _showJumpToPageDialog : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Page $_currentPage of $_totalPages',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: centerTextColor,
                              ),
                            ),
                            if (_totalPages > 1) ...[
                              SizedBox(width: 4),
                              Icon(
                                Icons.unfold_more_rounded,
                                size: 16,
                                color: Color(0xFF6C63FF),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          '${(progressVal * 100).toStringAsFixed(0)}% • Tap to jump',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? Colors.white60
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Next Page Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canGoNext
                        ? Color(0xFF6C63FF)
                        : (isDark ? Colors.white12 : Colors.grey.shade300),
                    foregroundColor: canGoNext
                        ? Colors.white
                        : (isDark ? Colors.white38 : Colors.grey.shade600),
                    elevation: canGoNext ? 1 : 0,
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: canGoNext ? _goToNextPage : null,
                  label: Text(
                    'Next',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  icon: Icon(Icons.chevron_right_rounded, size: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
