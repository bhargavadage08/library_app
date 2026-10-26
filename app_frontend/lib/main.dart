import 'package:flutter/material.dart';
import 'view/splash_screen.dart';

void main() {
  runApp(const OnlineBookLibraryApp());
}

class OnlineBookLibraryApp extends StatelessWidget {
  const OnlineBookLibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Online Book Library',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5B4636)),
      ),

      home: const SplashScreen(),
    );
  }
}
