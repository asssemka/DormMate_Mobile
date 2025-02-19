import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(), // Пустое место сверху
            Column(
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
                SizedBox(height: 50.h), 
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD50032),
                    padding: EdgeInsets.symmetric(horizontal: 90.w, vertical: 10.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                  child: Text(
                    'Log In',
                    style: GoogleFonts.josefinSans(fontSize: 22.sp, color: Colors.white),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 30.h),
              child: Image.asset(
                'assets/logo.png', // Логотип Narxoz
                width: 110.w, // Размер логотипа
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
