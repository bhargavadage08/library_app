import 'package:app_frontend/constant/color_const.dart';
import 'package:app_frontend/view/profile_screen.dart';
// import 'package:app_frontend/view/profile_screen.dart';
import 'package:flutter/material.dart';
import '../models/book_model.dart';
import 'home_page.dart';
import 'book_categories_page.dart';

class FavoritesScreen extends StatelessWidget {
  final List<Book> favoriteBook;

  const FavoritesScreen({super.key, required this.favoriteBook});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F5F0),
      appBar: AppBar(
        title: Text(
          'My Favorites',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Color(0xFF5B4636),
        iconTheme: IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: favoriteBook.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_border, size: 80, color: Colors.brown),
                  SizedBox(height: 16),
                  Text(
                    'No Favorite Books Yet!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Save your favorite books to read them later.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: favoriteBook.length,
              itemBuilder: (context, index) {
                final book = favoriteBook[index];

                return Card(
                  margin: EdgeInsets.only(bottom: 14),
                  elevation: 3,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: book.coverUrl != null
                          ? Image.network(
                              book.coverUrl!,
                              width: 65,
                              height: 90,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return SizedBox(
                                  width: 65,
                                  height: 90,
                                  child: Icon(
                                    Icons.menu_book,
                                    size: 40,
                                    color: Colors.brown,
                                  ),
                                );
                              },
                            )
                          : SizedBox(
                              width: 65,
                              height: 90,
                              child: Icon(
                                Icons.menu_book,
                                size: 40,
                                color: Colors.brown,
                              ),
                            ),
                    ),
                    title: Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        book.authors.isNotEmpty
                            ? book.authors.join(', ')
                            : 'Unknown Author',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    trailing: IconButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Connect this button to your favorites state',
                            ),
                          ),
                        );
                      },
                      icon: Icon(Icons.favorite, color: Colors.red),
                    ),
                  ),
                );
              },
            ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        selectedItemColor: AppColor.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,

        onTap: (index) {
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => BookCategoriesPage()),
            );
          } else if (index == 2) {
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfileScreen()),
            );
          }
        },

        items: [
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
}
