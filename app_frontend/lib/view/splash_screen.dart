
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_frontend/view/login_page.dart';
import '../constant/color_const.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    _navigationTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const LoginPage(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.backgroundColor,
      body: Center(
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
        
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  color: AppColor.primaryColor,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppColor.primaryColor.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  size: 65,
                  color: Colors.white,
                ),
              ),
        
              const SizedBox(height: 28),
        
              Text(
                'Book Haven',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppColor.primaryColor,
                ),
              ),
        
              const SizedBox(height: 12),
        
              const Text(
                'A world of stories, just for you',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF827568),
                ),
              ),
        
              const SizedBox(height: 40),
        
              SizedBox(
                height: 28,
                width: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColor.primaryColor,
                ),
              ),
        
              const Spacer(),
        
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Text(
                  'DISCOVER • READ • REPEAT',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                    color: Color(0xFF9A8C7C),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
