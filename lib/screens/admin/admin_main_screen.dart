import 'package:flutter/material.dart';
import '../../services/api.dart';               
import 'admin_home_screen.dart';
import 'admin_chat_list_screen.dart';
import 'admin_notifications_screen.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({Key? key}) : super(key: key);

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _current = 0;

  final List<Widget> _tabs = const [
    AdminHomeScreen(),
    AdminChatListScreen(),
    AdminNotificationsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.logout();
              if (!mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                  context, '/login', (_) => false);
            },
          ),
        ],
      ),
      body: _tabs[_current],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _current,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        onTap: (idx) => setState(() => _current = idx),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications), label: 'Notifs'),
        ],
      ),
    );
  }
}
