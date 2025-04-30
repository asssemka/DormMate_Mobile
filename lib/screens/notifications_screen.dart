import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../services/api.dart';

class NotificationsScreen extends StatefulWidget {
  final VoidCallback onOpenChat;
  const NotificationsScreen({Key? key, required this.onOpenChat}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> notifications = [];
  Timer? timer;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    timer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchNotifications());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchNotifications() async {
    try {
      final result = await NotificationsService.getNotifications();
      setState(() => notifications = result);
    } catch (e) {
      setState(() => error = 'Ошибка при загрузке уведомлений: \$e');
    }
  }

  String _formatDate(String iso) {
    final date = DateTime.tryParse(iso);
    if (date == null) return '';
    return DateFormat('MMMM d').format(date);
  }

  String _formatTime(String iso) {
    final date = DateTime.tryParse(iso);
    if (date == null) return '';
    return DateFormat('HH:mm').format(date);
  }

  Map<String, List<Map<String, dynamic>>> _groupByDate() {
    final map = <String, List<Map<String, dynamic>>>{};
    for (var n in notifications) {
      final dateKey = _formatDate(n['created_at']);
      map.putIfAbsent(dateKey, () => []).add(n);
    }
    return map;
  }

  BottomNavigationBar _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.red,
      unselectedItemColor: Colors.grey,
      currentIndex: 3,
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, '/home');
            break;
          case 1:
            Navigator.pushReplacementNamed(context, '/apply');
            break;
          case 2:
            Navigator.pushReplacementNamed(context, '/chat');
            break;
          case 3:
            Navigator.pushReplacementNamed(context, '/notification');
            break;
          case 4:
            Navigator.pushReplacementNamed(context, '/profile');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_customize_outlined), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.notifications_none_outlined), label: ''),
        BottomNavigationBarItem(icon: CircleAvatar(radius: 12, backgroundImage: AssetImage('assets/avatar.png')), label: ''),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByDate();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: error != null
            ? Center(child: Text(error!, style: const TextStyle(color: Colors.red)))
            : ListView(
                children: grouped.entries.map((entry) {
                  final date = entry.key;
                  final items = entry.value;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Text(date, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...items.map((n) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(n['message'] ?? '', style: const TextStyle(fontSize: 14))),
                                const SizedBox(width: 10),
                                Text(_formatTime(n['created_at']), style: const TextStyle(fontSize: 12, color: Colors.black54)),
                              ],
                            ),
                          )),
                    ],
                  );
                }).toList(),
              ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }
}
