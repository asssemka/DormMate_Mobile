import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'home_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.4, 
              child: Image.asset('assets/dorm_background.png', fit: BoxFit.cover),
              ),
              ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Spacer(), 
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'DORM MATE',
                        style: GoogleFonts.montserrat(
                          fontSize: 40.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFD50032),
                        ),
                      ),
                      SizedBox(height: 30.h),
                      _buildTextField('Login', Icons.person),
                      SizedBox(height: 16.h),
                      _buildTextField('Password', Icons.lock, isPassword: true),
                      SizedBox(height: 24.h),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD50032),
                          padding: EdgeInsets.symmetric(horizontal: 80.w, vertical: 14.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => HomePage()),
                          );
                        },
                        child: Text(
                          'Sign In',
                          style: GoogleFonts.josefinSans(fontSize: 18.sp, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Spacer(), // Оставляет место для логотипа
              Padding(
                padding: EdgeInsets.only(bottom: 30.h),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Image.asset(
                    'assets/logo.png',
                    width: 110.w,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String hint, IconData icon, {bool isPassword = false}) {
    return SizedBox(
      width: 280.w,
      child: TextField(
        obscureText: isPassword,
        style: GoogleFonts.josefinSans(fontSize: 16.sp),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
          prefixIcon: Icon(icon, color: Colors.grey, size: 22.sp),
          hintText: hint,
          hintStyle: GoogleFonts.josefinSans(fontSize: 16.sp, color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
