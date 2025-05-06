import 'package:flutter/material.dart';
import '../../services/api.dart';

/// Отображает конкретный чат (сообщения + поле ввода)
class AdminChatScreen extends StatefulWidget {
  final int chatId;
  final String studentName;

  const AdminChatScreen({
    Key? key,
    required this.chatId,
    required this.studentName,
  }) : super(key: key);

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  List<Map<String, dynamic>> messages = [];
  bool isLoading = false;
  String? error;
  TextEditingController inputCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final data = await ChatService.fetchMessages(widget.chatId);
      setState(() {
        messages = data.map<Map<String,dynamic>>((m) {
          // можно преобразовать timestamps
          return {
            "id": m["id"],
            "content": m["content"],
            "sender_type": m["sender_type"],
            "timestamp": m["timestamp"] ?? ""
          };
        }).toList();
      });
    } catch (e) {
      setState(() => error = "Ошибка при загрузке сообщений: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = inputCtrl.text.trim();
    if (text.isEmpty) return;
    try {
      await ChatService.sendMessage(widget.chatId, text);
      inputCtrl.clear();
      // Перезагрузим сообщения
      _loadMessages();
    } catch (e) {
      setState(() => error = "Ошибка при отправке: $e");
    }
  }

  Future<void> _endChat() async {
    try {
      await ChatService.endChat(widget.chatId);
      // Можно выключить ввод, показать «Чат завершён»
      setState(() {
        messages.add({
          "id": "end",
          "content": "Чат завершён.",
          "sender_type": "system",
          "timestamp": DateTime.now().toString()
        });
      });
    } catch (e) {
      setState(() => error = "Ошибка завершения чата: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Чат #${widget.chatId} со студентом: ${widget.studentName}"),
      ),
      body: Column(
        children: [
          if (error != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(error!, style: const TextStyle(color: Colors.red)),
            ),
          if (isLoading)
            const LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, i) {
                final msg = messages[i];
                final isAdmin = msg["sender_type"] == "admin";
                return Align(
                  alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isAdmin ? Colors.blueAccent : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(msg["content"] ?? "",
                          style: TextStyle(color: isAdmin ? Colors.white : Colors.black),
                        ),
                        Text(
                          msg["timestamp"] ?? "",
                          style: TextStyle(
                            fontSize: 10,
                            color: isAdmin ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Поле ввода
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: inputCtrl,
                    decoration: const InputDecoration(hintText: "Введите сообщение..."),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
          // Кнопка завершения чата
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _endChat,
              child: const Text("Завершить чат"),
            ),
          ),
        ],
      ),
    );
  }
}
