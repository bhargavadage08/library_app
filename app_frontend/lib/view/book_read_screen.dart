import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../repo/book_repo.dart';

class BookReaderScreen extends StatefulWidget {
  final Book book;

  const BookReaderScreen({super.key, required this.book});

  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen> {
  final BookRepository _repository = BookRepository();

  late Future<String> _contentFuture;
  double _fontSize = 17;

  @override
  void initState() {
    super.initState();
    _contentFuture = _repository.fetchBookContent(widget.book);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFCF5),
      appBar: AppBar(
        backgroundColor: Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        title: Text(
          widget.book.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
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
                if (_fontSize < 28) _fontSize += 1;
              });
            },
            icon: Icon(Icons.text_increase),
          ),
        ],
      ),
      body: FutureBuilder<String>(
        future: _contentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.menu_book_outlined,
                      size: 55,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'The book may not provide a supported text format, '
                      'or the server may be unavailable.',
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _contentFuture = _repository.fetchBookContent(
                            widget.book,
                          );
                        });
                      },
                      child: Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final content = snapshot.data ?? '';

          return SelectionArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.auto_stories_rounded,
                          size: 42,
                          color: Color(0xFF6C63FF),
                        ),
                        SizedBox(height: 12),
                        Text(
                          widget.book.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          widget.book.authorName,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54, fontSize: 15),
                        ),
                        SizedBox(height: 22),
                        Divider(),
                        SizedBox(height: 22),
                      ],
                    ),
                  ),
                  Text(
                    content,
                    style: TextStyle(
                      fontSize: _fontSize,
                      height: 1.8,
                      color: Color(0xFF302D2D),
                    ),
                  ),
                  SizedBox(height: 40),
                  Center(
                    child: Text(
                      'End of available text',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
