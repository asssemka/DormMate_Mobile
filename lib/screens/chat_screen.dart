import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api.dart';

class StudentChatScreen extends StatefulWidget {
  @override
  _StudentChatScreenState createState() => _StudentChatScreenState();
}

class _StudentChatScreenState extends State<StudentChatScreen> {
  int? chatId;
  List<Map<String, dynamic>> messages = [];
  TextEditingController inputController = TextEditingController();
  bool chatActive = true;
  Timer? fetchTimer;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    try {
      chatId = await ChatService.getStudentChat();
      _fetchMessages();
      fetchTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchMessages());
    } catch (e) {
      print("Ошибка при инициализации чата: $e");
    }
  }

  Future<void> _fetchMessages() async {
    if (chatId == null) return;
    try {
      final data = await ChatService.fetchMessages(chatId!);
      setState(() {
        messages = data.map<Map<String, dynamic>>((msg) => {
          'id': msg['id'],
          'text': msg['content'],
          'type': msg['sender_type'],
          'timestamp': msg['timestamp'] ?? '',
        }).toList();
      });
    } catch (e) {
      print("Ошибка при загрузке сообщений: $e");
    }
  }

  Future<void> _handleSendMessage() async {
    final text = inputController.text.trim();
    if (text.isEmpty || !chatActive || chatId == null) return;
    inputController.clear();

    try {
      await ChatService.sendMessage(chatId!, text);
      _fetchMessages();

      final autoAnswer = await ChatService.searchAutoAnswer(text);
      if (autoAnswer != null) {
        setState(() {
          messages.add({
            'id': DateTime.now().millisecondsSinceEpoch,
            'text': autoAnswer,
            'type': 'admin',
            'timestamp': TimeOfDay.now().format(context),
          });
        });
      } else {
        setState(() {
          messages.add({
            'id': DateTime.now().millisecondsSinceEpoch + 1,
            'text': 'Администратор подключается к чату...',
            'type': 'admin',
            'timestamp': TimeOfDay.now().format(context),
          });
        });
      }
    } catch (e) {
      print("Ошибка при отправке сообщения: $e");
    }
  }

  Future<void> _requestOperator() async {
    if (chatId == null || !chatActive) return;
    try {
      await ChatService.requestAdmin(chatId!);
      setState(() {
        messages.add({
          'id': DateTime.now().millisecondsSinceEpoch + 2,
          'text': 'Оператор вызван. Ожидайте...',
          'type': 'admin',
          'timestamp': TimeOfDay.now().format(context),
        });
      });
    } catch (e) {
      print("Ошибка вызова оператора: $e");
    }
  }

  Future<void> _endChat() async {
    if (chatId == null || !chatActive) return;
    try {
      await ChatService.endChat(chatId!);
      setState(() {
        chatActive = false;
        messages.add({
          'id': 'end',
          'text': 'Чат завершён.',
          'type': 'admin',
          'timestamp': TimeOfDay.now().format(context),
        });
      });
    } catch (e) {
      print("Ошибка завершения чата: $e");
    }
  }

  @override
  void dispose() {
    fetchTimer?.cancel();
    inputController.dispose();
    super.dispose();
  }

  Widget _chatBubble(String text, bool isUser, String time) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? Colors.lightBlueAccent : Colors.grey.shade300,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                fontSize: 10,
                color: isUser ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: const [
            CircleAvatar(
              radius: 20,
              backgroundImage: AssetImage('assets/chatbot.png'),
            ),
            SizedBox(height: 4),
            Text('ChatBot', style: TextStyle(color: Colors.black, fontSize: 16)),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: false,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isUser = msg['type'] == 'student';
                return _chatBubble(msg['text'], isUser, msg['timestamp']);
              },
            ),
          ),
          if (chatActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  const Icon(Icons.add_circle_outline, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: inputController,
                      decoration: const InputDecoration(
                        hintText: 'Enter text message',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _handleSendMessage(),
                    ),
                  ),
                  GestureDetector(
                    onTap: _handleSendMessage,
                    child: const CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.green,
                      child: Icon(Icons.arrow_upward, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          if (chatActive)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _requestOperator,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                    child: const Text('Вызвать оператора'),
                  ),
                  ElevatedButton(
                    onPressed: _endChat,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Завершить чат'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}