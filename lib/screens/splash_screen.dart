import 'package:flutter/material.dart';
import 'welcome_screen.dart'; // Импортируем WelcomeScreen

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration(seconds: 1), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => WelcomeScreen()), // Переход на WelcomeScreen
      );
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/logo.png', 
          width: 200, // Сделал размер чуть меньше для аккуратности
        ),
      ),
    );
  }
}
