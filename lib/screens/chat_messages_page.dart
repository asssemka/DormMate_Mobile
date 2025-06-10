import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat.dart';
import '../providers/chat_provider.dart';
import '../services/api.dart'; // <-- добавь импорт

class ChatMessagesPage extends StatefulWidget {
  final Chat chat;
  const ChatMessagesPage({Key? key, required this.chat}) : super(key: key);

  @override
  State<ChatMessagesPage> createState() => _ChatMessagesPageState();
}

class _ChatMessagesPageState extends State<ChatMessagesPage> {
  final _controller = TextEditingController();
  String? _accessToken;

  @override
  void initState() {
    super.initState();

    // Проверим токен сразу при открытии страницы чата
    AuthService.getAccessToken().then((token) {
      setState(() {
        _accessToken = token;
      });
      debugPrint("ACCESS TOKEN IN CHAT PAGE: $token");
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().selectChat(widget.chat);
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatProv = context.watch<ChatProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chat.name ?? "Чат"),
        // Можешь для теста временно показать токен в appbar
        bottom: _accessToken != null
            ? PreferredSize(
                preferredSize: const Size.fromHeight(36),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text(
                    'Token: ${_accessToken}',
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          // Можно вывести токен и тут (для наглядности)
          if (_accessToken != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Access Token: $_accessToken',
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: chatProv.messages.length,
              itemBuilder: (ctx, i) {
                final msg = chatProv.messages[i];
                final isMe = msg.senderType == 'student';
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue.shade100 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(msg.content),
                        const SizedBox(height: 4),
                        Text(
                          "${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}",
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Введите сообщение...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () async {
                      final text = _controller.text.trim();
                      if (text.isEmpty) return;
                      await context.read<ChatProvider>().sendMessage(text);
                      _controller.clear();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
