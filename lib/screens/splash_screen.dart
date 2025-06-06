import 'package:flutter/material.dart';
import 'welcome_screen.dart';

class SplashScreen extends StatelessWidget {
  final Function(Locale) onLanguageChanged;
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;

  const SplashScreen({
    Key? key,
    required this.onLanguageChanged,
    required this.onToggleTheme,
    required this.themeMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration(seconds: 1), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => WelcomeScreen()),
      );
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/logo.png',
          width: 200,
        ),
      ),
    );
  }
}
