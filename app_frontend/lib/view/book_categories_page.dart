import 'package:flutter/material.dart';
import 'home_page.dart';
import 'favorites_screen.dart';
import '../constant/color_const.dart';

class BookCategoriesPage extends StatelessWidget {
  const BookCategoriesPage({super.key});

  final List<Map<String, dynamic>> categories = const [
    {'name': 'Fiction', 'icon': Icons.auto_stories, 'color': Color(0xFF7C4DFF)},
    {'name': 'Science', 'icon': Icons.science, 'color': Color(0xFF009688)},
    {'name': 'History', 'icon': Icons.history_edu, 'color': Color(0xFFFF9800)},
    {
      'name': 'Romance',
      'icon': Icons.manage_search,
      'color': Color(0xFF3F51B5),
    },
    {'name': 'Biography', 'icon': Icons.person, 'color': Color(0xFF00ACC1)},
    {'name': 'Education', 'icon': Icons.school, 'color': Color(0xFF795548)},
    {
      'name': 'Romance',
      'icon': Icons.manage_search,
      'color': Color(0xFF4CAF50),
    },
    {'name': 'Fantasy', 'icon': Icons.auto_awesome, 'color': Color(0xFF9C27B0)},
    {'name': 'Adventure', 'icon': Icons.explore, 'color': Color(0xFFFF5722)},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomePage()),
              );
            }
          },
        ),
        title: const Text(
          'Book Categories',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Explore Categories',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF25213B),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Find your next favorite book.',
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),
              SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  itemCount: categories.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.12,
                  ),
                  itemBuilder: (context, index) {
                    final category = categories[index];

                    return InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        final categoryName = category['name'] as String;
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context, categoryName);
                        } else {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  HomePage(initialCategory: categoryName),
                            ),
                          );
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              height: 65,
                              width: 65,
                              decoration: BoxDecoration(
                                color: (category['color'] as Color).withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Icon(
                                category['icon'] as IconData,
                                color: category['color'] as Color,
                                size: 32,
                              ),
                            ),
                            SizedBox(height: 14),
                            Text(
                              category['name'] as String,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF25213B),
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Explore Books',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
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
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => FavoritesScreen(favoriteBook: [],)),
            );
          } else if (index == 3) {}
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
