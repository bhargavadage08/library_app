import 'dart:async';
import 'package:flutter/material.dart';
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

    _navigationTimer = Timer(Duration(seconds: 3), () {
      if (!mounted) return;
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
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 130,
                width: 130,
                decoration: BoxDecoration(
                  color: AppColor.primaryColor,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: AppColor.primaryColor.withValues(alpha: 0.20),
                      blurRadius: 25,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  size: 72,
                  color: Colors.white,
                ),
              ),


              SizedBox(height: 30,),


              Text(
                'Book Haven',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppColor.primaryColor,
                ),
              ),


              SizedBox(height: 12,),




              Text(
                'A world of stories, just for you',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF827568),
                  letterSpacing: 0.4,
                ),
              ),




              SizedBox(height: 45,),






              SizedBox(
                height: 28,
                width: 28,
                child: CircularProgressIndicator(
                  strokeAlign: 3,
                  color: AppColor.primaryColor,
                ),
              )
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(bottom: 28),
        child: Text(
          'DISCOVER * READ * REPEAT',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
            color: Color(0xFF9A8C7C),
          ),
        ),
      ),
    );
  }
}
