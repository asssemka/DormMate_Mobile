import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api.dart';
import '../gen_l10n/app_localizations.dart';

class StudentChatScreen extends StatefulWidget {
  @override
  _StudentChatScreenState createState() => _StudentChatScreenState();
}

class _StudentChatScreenState extends State<StudentChatScreen> with TickerProviderStateMixin {
  int? chatId;
  List<Map<String, dynamic>> messages = [];
  TextEditingController inputController = TextEditingController();
  bool chatActive = true;
  Timer? fetchTimer;
  final _listKey = GlobalKey<AnimatedListState>();

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
        messages = data.map<Map<String, dynamic>>((msg) {
          final timestampStr = msg['timestamp'] ?? '';
          String formattedTime = '';
          try {
            final date = DateTime.parse(timestampStr);
            formattedTime =
                '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
          } catch (e) {
            formattedTime = '';
          }
          return {
            'id': msg['id'],
            'text': msg['content'],
            'type': msg['sender_type'],
            'timestamp': formattedTime,
          };
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
      final now = DateTime.now();
      final formattedNow =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      if (autoAnswer != null) {
        setState(() {
          messages.add({
            'id': DateTime.now().millisecondsSinceEpoch,
            'text': autoAnswer,
            'type': 'admin',
            'timestamp': formattedNow,
          });
        });
      } else {
        setState(() {
          messages.add({
            'id': DateTime.now().millisecondsSinceEpoch + 1,
            'text':
                AppLocalizations.of(context)!.operator, // "Администратор подключается к чату..."
            'type': 'admin',
            'timestamp': formattedNow,
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
      final now = DateTime.now();
      final formattedNow =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      setState(() {
        messages.add({
          'id': DateTime.now().millisecondsSinceEpoch + 2,
          'text': AppLocalizations.of(context)!.operator +
              '. ' +
              AppLocalizations.of(context)!.success, // Например: "Оператор вызван. Ожидайте..."
          'type': 'admin',
          'timestamp': formattedNow,
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
      final now = DateTime.now();
      final formattedNow =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      setState(() {
        chatActive = false;
        messages.add({
          'id': 'end',
          'text': AppLocalizations.of(context)!.end_chat,
          'type': 'admin',
          'timestamp': formattedNow,
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

  Widget _chatBubble(String text, bool isUser, String time, ThemeData theme,
      {Animation<double>? animation}) {
    final isDark = theme.brightness == Brightness.dark;
    final userColor = isDark ? Color(0xFF2E3B5B) : Color(0xFFDCE3F6);
    final adminColor = isDark ? Color(0xFF232338) : Colors.white;
    final borderUser = isDark ? Color(0xFF395380) : Color(0xFFB1BCDD);
    final borderAdmin = isDark ? Color(0xFF22243A) : Color(0xFFE1E4F0);

    final bubbleColor = isUser ? userColor : adminColor;
    final borderColor = isUser ? borderUser : borderAdmin;

    final userTextColor = isUser
        ? (isDark ? Colors.white : Color(0xFF2E3B5B))
        : (isDark ? Colors.white : Colors.black87);
    final timeColor = isUser ? Colors.grey[400]! : Colors.grey[500]!;

    Widget child = Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 5),
            bottomRight: Radius.circular(isUser ? 5 : 18),
          ),
          border: Border.all(color: borderColor.withOpacity(0.4), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: (isUser ? borderUser : borderAdmin).withOpacity(0.12),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              text,
              style: GoogleFonts.montserrat(
                color: userTextColor,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: GoogleFonts.montserrat(
                fontSize: 11,
                color: timeColor,
              ),
            ),
          ],
        ),
      ),
    );

    // Оборачиваем в FadeTransition для плавного появления (если передали animation)
    if (animation != null) {
      child = FadeTransition(opacity: animation, child: child);
    }

    return child;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? Color(0xFF181825) : Color(0xFFF7F7FA);
    final appBarBg = isDark ? Color(0xFF232338) : Colors.white;
    final appBarTextColor = isDark ? Colors.white : Color(0xFF232338);
    final inputBg = isDark ? Color(0xFF22232A) : Colors.white;
    final inputTextColor = isDark ? Colors.white : Colors.black87;
    final sendIconBg = Color(0xFFD50032);
    final sendIconColor = Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: appBarBg,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: appBarTextColor),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
        ),
        title: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: appBarBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.support_agent,
                color: appBarTextColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              t.chatbot,
              style: GoogleFonts.montserrat(
                color: appBarTextColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Список сообщений с анимацией появления
          Expanded(
            child: ListView.builder(
              reverse: false,
              padding: const EdgeInsets.only(top: 12, bottom: 2),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isUser = msg['type'] == 'student';
                return _chatBubble(
                  msg['text'],
                  isUser,
                  msg['timestamp'],
                  theme,
                  // можно добавить анимацию вручную через AnimatedList, если нужно
                );
              },
            ),
          ),
          if (chatActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: inputBg,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: inputController,
                      style: GoogleFonts.montserrat(color: inputTextColor),
                      decoration: InputDecoration(
                        hintText: t.send_message_hint,
                        hintStyle:
                            GoogleFonts.montserrat(color: isDark ? Colors.grey[400] : Colors.grey),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _handleSendMessage(),
                    ),
                  ),
                  GestureDetector(
                    onTap: _handleSendMessage,
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 180),
                      curve: Curves.easeIn,
                      decoration: BoxDecoration(
                        color: sendIconBg,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFD50032).withOpacity(0.18),
                            blurRadius: 7,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Icon(Icons.arrow_upward, color: sendIconColor, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          if (chatActive)
            Padding(
              padding: const EdgeInsets.only(bottom: 15, top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _requestOperator,
                    icon: Icon(Icons.support_agent, color: Color(0xFFD50032)),
                    label: Text(
                      t.operator,
                      style: GoogleFonts.montserrat(
                          color: Color(0xFFD50032), fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                      elevation: 0,
                      side: BorderSide(color: Color(0xFFD50032), width: 1.2),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _endChat,
                    icon: Icon(Icons.close, color: Color(0xFFC72727)),
                    label: Text(
                      t.end_chat,
                      style: GoogleFonts.montserrat(
                          color: Color(0xFFC72727), fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                      elevation: 0,
                      side: const BorderSide(color: Color(0xFFC72727), width: 1.2),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
