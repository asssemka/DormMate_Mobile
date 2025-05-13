import 'package:flutter/material.dart';
import '/screens/apply_screen.dart';

void main() {
  runApp(DormMateApp());
}

class DormMateApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(),  
        '/apply': (context) => ApplyScreen(), // Исправлено здесь
        '/chat': (context) => ChatScreen(),
        '/profile': (context) => ProfileScreen(),
      },
    );
  }
}

// Проверяем, нужно ли отображать BottomNavigationBar
bool _shouldShowBottomNavBar(BuildContext context) {
  final String? currentRoute = ModalRoute.of(context)?.settings.name;
  return currentRoute != '/login';
}

// Виджет BottomNavigationBar
class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  BottomNavBar({required this.currentIndex});

  void _onTabTapped(BuildContext context, int index) {
    String route = '/';
    switch (index) {
      case 1:
        route = '/apply';
        break;
      case 2:
        route = '/chat';
        break;
      case 3:
        route = '/profile';
        break;
    }

    if (ModalRoute.of(context)?.settings.name != route) {
      Navigator.pushReplacementNamed(context, route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      selectedItemColor: Colors.red,
      unselectedItemColor: Colors.grey,
      currentIndex: currentIndex,
      onTap: (index) => _onTabTapped(context, index),
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.app_registration), label: 'Apply'),
        BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}

// Экраны
class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/');
          },
          child: Text('Войти'),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Home Screen')),
      bottomNavigationBar: BottomNavBar(currentIndex: 0),
    );
  }
}

class ApplyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Apply Screen')),
      bottomNavigationBar: BottomNavBar(currentIndex: 1),
    );
  }
}

class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Chat Screen')),
      bottomNavigationBar: BottomNavBar(currentIndex: 2),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Profile Screen')),
      bottomNavigationBar: BottomNavBar(currentIndex: 3),
    );
  }
}
