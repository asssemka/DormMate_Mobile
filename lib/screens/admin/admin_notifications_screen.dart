import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({Key? key}) : super(key: key);

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  List<Map<String, dynamic>> notifications = [];
  String? error;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    timer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchNotifications());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchNotifications() async {
    try {
      final data = await NotificationsService.getAdminNotifications(); 
      setState(() {
        notifications = data;
      });
    } catch (e) {
      setState(() => error = "Ошибка при загрузке уведомлений: $e");
    }
  }

  Future<void> _markAsRead(int id) async {
    try {
      await NotificationsService.markAdminAsRead([id]); 
      setState(() {
        notifications.removeWhere((n) => n["id"] == id);
      });
    } catch (e) {
      setState(() => error = "Ошибка при отметке: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Center(child: Text(error!, style: const TextStyle(color: Colors.red)));
    }
    if (notifications.isEmpty) {
      return const Center(child: Text("Нет уведомлений"));
    }
    return ListView.builder(
      itemCount: notifications.length,
      itemBuilder: (context, i) {
        final n = notifications[i];
        return ListTile(
          title: Text(n["message"] ?? ""),
          subtitle: Text(n["created_at"] ?? ""),
          trailing: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _markAsRead(n["id"] as int),
          ),
        );
      },
    );
  }
}
