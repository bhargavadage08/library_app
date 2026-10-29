import 'package:flutter/material.dart';

import '../constant/color_const.dart';
import '../models/reading_models.dart';
import '../repo/auth_repo.dart';
import '../repo/book_repo.dart';
import 'book_read_screen.dart';
import 'login_page.dart';

class ReadingHistoryScreen extends StatefulWidget {
  const ReadingHistoryScreen({super.key});

  @override
  State<ReadingHistoryScreen> createState() => _ReadingHistoryScreenState();
}

class _ReadingHistoryScreenState extends State<ReadingHistoryScreen> {
  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color backgroundColor = Color(0xFFF8F7FF);

  final AuthService _authService = AuthService();
  final BookRepository _bookRepository = BookRepository();

  List<ReadingHistoryItem> _allHistory = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedFilterIndex = 0; // 0: All, 1: In Progress, 2: Completed

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (!mounted) return;

    if (!_authService.isAuthenticated) {
      setState(() {
        _isLoading = false;
        _errorMessage = null;
        _allHistory = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _bookRepository.fetchReadingHistory();
      if (!mounted) return;

      setState(() {
        _allHistory = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  List<ReadingHistoryItem> get _filteredHistory {
    if (_selectedFilterIndex == 1) {
      return _allHistory.where((item) => !item.isCompleted).toList();
    } else if (_selectedFilterIndex == 2) {
      return _allHistory.where((item) => item.isCompleted).toList();
    }
    return _allHistory;
  }

  Future<void> _deleteItem(ReadingHistoryItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title:   Text('Remove from History'),
        content: Text(
          'Remove "${item.title}" from your reading history? This will reset your saved progress for this book.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:   Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child:   Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final removedIndex = _allHistory.indexWhere((h) => h.id == item.id);
    final removedItem = item;

    setState(() {
      _allHistory.removeWhere((h) => h.id == item.id);
    });

    try {
      final success = await _bookRepository.deleteReadingHistoryItem(item.bookId);
      if (!success && mounted) {
        setState(() {
          if (removedIndex != -1) {
            _allHistory.insert(removedIndex, removedItem);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to remove book from history')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed "${item.title}" from history'),
            duration:   Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (removedIndex != -1) {
            _allHistory.insert(removedIndex, removedItem);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _clearAllHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title:   Text('Clear All Reading History'),
        content:   Text(
          'Are you sure you want to delete your entire reading history? '
          'All your book reading progress will be permanently erased.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:   Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child:   Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      final success = await _bookRepository.clearReadingHistory();
      if (!mounted) return;

      if (success) {
        setState(() {
          _allHistory.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Reading history cleared successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to clear reading history')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error clearing history: $e')),
        );
      }
    }
  }

  Future<void> _continueReading(ReadingHistoryItem item) async {
    final book = item.toBook();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookReaderScreen(
          book: book,
          initialPage: item.currentPage,
        ),
      ),
    );

    // Refresh history when user returns from reading
    if (mounted) {
      _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final isLoggedIn = _authService.isAuthenticated;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              Text(
              'Reading History',
              style: TextStyle(
                color: Color(0xFF24213A),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isLoggedIn && user != null)
              Text(
                'for ${user.fullName} (${user.email})',
                style:   TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadHistory,
            icon:   Icon(Icons.refresh_rounded, color: primaryColor),
          ),
          if (isLoggedIn && _allHistory.isNotEmpty)
            PopupMenuButton<String>(
              icon:   Icon(Icons.more_vert_rounded, color: Colors.grey),
              onSelected: (value) {
                if (value == 'clear') {
                  _clearAllHistory();
                }
              },
              itemBuilder: (context) => [
                  PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep_rounded, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Clear All History', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _buildContent(isLoggedIn, user),
    );
  }

  Widget _buildContent(bool isLoggedIn, dynamic user) {
    if (!isLoggedIn) {
      return _buildGuestState();
    }

    if (_isLoading) {
      return   Center(
        child: CircularProgressIndicator(color: primaryColor),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_allHistory.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadHistory,
        color: primaryColor,
        child: ListView(
          physics:   AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: _buildEmptyState(),
            ),
          ],
        ),
      );
    }

    final inProgressCount = _allHistory.where((h) => !h.isCompleted).length;
    final completedCount = _allHistory.where((h) => h.isCompleted).length;
    final itemsToDisplay = _filteredHistory;

    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: primaryColor,
      child: ListView(
        physics:   AlwaysScrollableScrollPhysics(),
        padding:   EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        children: [
          // User Journey Summary Card
          _buildSummaryCard(
            userName: user?.fullName ?? 'Reader',
            totalBooks: _allHistory.length,
            inProgress: inProgressCount,
            completed: completedCount,
          ),

            SizedBox(height: 18),

          // Filter Tabs (All, In Progress, Completed)
          _buildFilterTabs(
            total: _allHistory.length,
            inProgress: inProgressCount,
            completed: completedCount,
          ),

            SizedBox(height: 16),

          // Section Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedFilterIndex == 0
                    ? 'All History (${itemsToDisplay.length})'
                    : _selectedFilterIndex == 1
                        ? 'Currently Reading (${itemsToDisplay.length})'
                        : 'Completed Books (${itemsToDisplay.length})',
                style:   TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF24213A),
                ),
              ),
              Text(
                'Sorted by recent',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),

            SizedBox(height: 12),

          if (itemsToDisplay.isEmpty)
            Container(
              padding:   EdgeInsets.all(32),
              alignment: Alignment.center,
              child: Text(
                _selectedFilterIndex == 1
                    ? 'No books currently in progress.'
                    : 'No completed books yet.',
                style:   TextStyle(color: Colors.grey, fontSize: 14),
              ),
            )
          else
            ...itemsToDisplay.map((item) => _buildHistoryCard(item)),

            SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String userName,
    required int totalBooks,
    required int inProgress,
    required int completed,
  }) {
    return Container(
      padding:   EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient:   LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF8C84FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.3),
            blurRadius: 16,
            offset:   Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:   EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child:   Icon(
                  Icons.auto_stories_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
                SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$userName\'s Reading Journey',
                      style:   TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                      SizedBox(height: 3),
                      Text(
                      'Synced per your account',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
            SizedBox(height: 18),
          Container(
            padding:   EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatPill('Total Read', '$totalBooks', Icons.bookmark_added_rounded),
                Container(height: 28, width: 1, color: Colors.white24),
                _buildStatPill('In Progress', '$inProgress', Icons.timelapse_rounded),
                Container(height: 28, width: 1, color: Colors.white24),
                _buildStatPill('Completed', '$completed', Icons.check_circle_outline_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 14),
              SizedBox(width: 4),
            Text(
              value,
              style:   TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
          SizedBox(height: 2),
        Text(
          label,
          style:   TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTabs({
    required int total,
    required int inProgress,
    required int completed,
  }) {
    final filters = [
      {'label': 'All', 'count': total},
      {'label': 'In Progress', 'count': inProgress},
      {'label': 'Completed', 'count': completed},
    ];

    return Row(
      children: List.generate(filters.length, (index) {
        final isSelected = _selectedFilterIndex == index;
        final f = filters[index];
        return Padding(
          padding:   EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text('${f['label']} (${f['count']})'),
            selected: isSelected,
            onSelected: (val) {
              if (val) {
                setState(() {
                  _selectedFilterIndex = index;
                });
              }
            },
            selectedColor: primaryColor,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white :   Color(0xFF24213A),
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            backgroundColor: Colors.white,
            side: BorderSide(
              color: isSelected ? primaryColor : Colors.grey.shade300,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHistoryCard(ReadingHistoryItem item) {
    final progress = item.progressFraction;
    final percentInt = (progress * 100).round();
    final isDone = item.isCompleted;

    return Container(
      margin:   EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset:   Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _continueReading(item),
          child: Padding(
            padding:   EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book Cover with rounded clip
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 82,
                    height: 120,
                    child: item.coverUrl != null && item.coverUrl!.isNotEmpty
                        ? Image.network(
                            item.coverUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _coverPlaceholder(),
                          )
                        : _coverPlaceholder(),
                  ),
                ),

                  SizedBox(width: 14),

                // Book Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Chip & Delete button
                      Row(
                        children: [
                          Container(
                            padding:   EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isDone
                                  ?   Color(0xFFE8F8F0)
                                  : primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isDone
                                      ? Icons.check_circle_rounded
                                      : Icons.timelapse_rounded,
                                  size: 11,
                                  color: isDone
                                      ?   Color(0xFF10B981)
                                      : primaryColor,
                                ),
                                  SizedBox(width: 4),
                                Text(
                                  isDone ? 'Finished' : 'In Progress',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isDone
                                        ?   Color(0xFF10B981)
                                        : primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                            Spacer(),
                          IconButton(
                            icon:   Icon(Icons.delete_outline_rounded, size: 19),
                            color: Colors.grey.shade400,
                            padding: EdgeInsets.zero,
                             constraints:   BoxConstraints(),
                            tooltip: 'Remove from history',
                            onPressed: () => _deleteItem(item),
                          ),
                        ],
                      ),

                        SizedBox(height: 6),

                      // Title
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:   TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF24213A),
                          height: 1.25,
                        ),
                      ),

                        SizedBox(height: 4),

                      // Author
                      Text(
                        item.displayAuthor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),

                        SizedBox(height: 10),

                      // Progress Bar & Percentage
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.pageProgressText,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '$percentInt%',
                            style: TextStyle(
                              color: isDone
                                  ?   Color(0xFF10B981)
                                  : primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                        SizedBox(height: 6),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor:   Color(0xFFECEBFA),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDone ?   Color(0xFF10B981) : primaryColor,
                          ),
                        ),
                      ),

                        SizedBox(height: 8),

                      // Footer: Last read & Continue Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 12,
                                color: Colors.grey.shade500,
                              ),
                                SizedBox(width: 4),
                              Text(
                                item.lastReadFormatted,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: () => _continueReading(item),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding:   EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    isDone ? 'Read Again' : 'Continue',
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                    SizedBox(width: 2),
                                    Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 13,
                                    color: primaryColor,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      color:   Color(0xFFECEBFA),
      child:   Center(
        child: Icon(
          Icons.menu_book_rounded,
          size: 32,
          color: primaryColor,
        ),
      ),
    );
  }

  Widget _buildGuestState() {
    return Center(
      child: Padding(
        padding:   EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding:   EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child:   Icon(
                Icons.lock_person_rounded,
                size: 64,
                color: primaryColor,
              ),
            ),
              SizedBox(height: 24),
              Text(
              'Sign In to View History',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF24213A),
              ),
            ),
              SizedBox(height: 10),
            Text(
              'Your reading progress, bookmarks, and completed books are saved securely under your personal account.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
              SizedBox(height: 26),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) =>   LoginPage()),
                ).then((_) => _loadHistory());
              },
              icon:   Icon(Icons.login_rounded),
              label:   Text('Log In / Register'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding:   EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding:   EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding:   EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_stories_outlined,
                size: 72,
                color: primaryColor.withValues(alpha: 0.7),
              ),
            ),
              SizedBox(height: 22),
              Text(
              'No Reading History Yet',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: Color(0xFF24213A),
              ),
            ),
              SizedBox(height: 10),
            Text(
              'Start reading any book from our library and your progress will automatically appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
              SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon:   Icon(Icons.library_books_rounded),
              label:   Text('Browse Library'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding:   EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding:   EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
              Icon(
              Icons.cloud_off_rounded,
              size: 64,
              color: Colors.redAccent,
            ),
              SizedBox(height: 16),
              Text(
              'Unable to load reading history',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF24213A),
              ),
            ),
              SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Network or server error',
              textAlign: TextAlign.center,
              style:   TextStyle(color: Colors.grey, fontSize: 13),
            ),
              SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadHistory,
              icon:   Icon(Icons.refresh_rounded),
              label:   Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
