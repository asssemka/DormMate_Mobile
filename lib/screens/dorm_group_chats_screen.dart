import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../models/chat.dart';
import 'chat_messages_page.dart';

class DormGroupChatsScreen extends StatelessWidget {
  const DormGroupChatsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final chatProv = context.watch<ChatProvider>();
    final chats = chatProv.chats;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Групповые чаты общежития'),
      ),
      body: chats.isEmpty
          ? const Center(child: Text('Чаты не найдены'))
          : ListView.builder(
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                return ListTile(
                  leading: const Icon(Icons.chat_bubble_outline),
                  title: Text(chat.name ?? 'Без названия'),
                  subtitle: Text(chat.type == 'dorm' ? 'Чат общежития' : 'Чат этажа ${chat.floor}'),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ChatMessagesPage(chat: chat),
                    ));
                  },
                );
              },
            ),
    );
  }
}
