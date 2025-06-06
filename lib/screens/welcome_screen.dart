import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Получаем текущие цвета из темы
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor =
        Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(), // пустой блок сверху для баланса
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'DORM MATE',
                      style: GoogleFonts.montserrat(
                        fontSize: 38.sp,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFD50032),
                        letterSpacing: 1.2,
                        // используем textColor если хочешь изменить цвет текста в тёмной теме
                        // color: textColor,
                      ),
                    ),
                    SizedBox(height: 40.h),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD50032),
                        padding: EdgeInsets.symmetric(horizontal: 110.w, vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 6,
                        shadowColor: const Color(0xFFD50032).withOpacity(0.25),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                      child: Text(
                        'Log In',
                        style: GoogleFonts.josefinSans(
                          fontSize: 22.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 110.h,
                  child: Image.asset(
                    'assets/logo.png',
                    width: 110.w,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
