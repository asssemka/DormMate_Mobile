import 'package:flutter/material.dart';
import '../../services/api.dart';
import 'admin_chat_screen.dart';

/// Список активных чатов. Похоже на ChatList (React).
class AdminChatListScreen extends StatefulWidget {
  const AdminChatListScreen({Key? key}) : super(key: key);

  @override
  State<AdminChatListScreen> createState() => _AdminChatListScreenState();
}

class _AdminChatListScreenState extends State<AdminChatListScreen> {
  List<Map<String, dynamic>> chats = [];
  String? error;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchChats();
  }

  Future<void> _fetchChats() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final data = await ChatService.fetchAllChats(); 
      // Предположим, что ChatService.fetchAllChats() -> GET /chats/ 
      // возвращает List<Map<String, dynamic>>
      setState(() {
        chats = data;
      });
    } catch (e) {
      setState(() {
        error = 'Ошибка при загрузке чатов: $e';
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _openChat(int chatId, String studentName) {
    // Переходим на AdminChatScreen 
    // через push (или pushNamed, как тебе удобнее)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminChatScreen(
          chatId: chatId,
          studentName: studentName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(child: Text(error!, style: const TextStyle(color: Colors.red)));
    }
    if (chats.isEmpty) {
      return const Center(child: Text('Нет активных чатов'));
    }

    return ListView.builder(
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final chat = chats[index];
        // Предположим, у нас есть chat["student"] = { "s", "first_name", "last_name" }, 
        // chat["id"], chat["has_new_messages"]
        final student = chat["student"] as Map<String, dynamic>;
        final chatId = chat["id"] as int;
        final hasNew = chat["has_new_messages"] == true;

        final studentName = "${student["s"]} ${student["first_name"]} ${student["last_name"]}";

        return ListTile(
          title: Text("Чат #$chatId с $studentName"),
          subtitle: hasNew ? const Text("Есть новые сообщения") : null,
          onTap: () => _openChat(chatId, studentName),
        );
      },
    );
  }
}
