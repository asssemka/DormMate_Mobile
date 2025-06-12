import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/chat.dart';
import '../providers/chat_provider.dart';
import '../providers/student_provider.dart';
import '../gen_l10n/app_localizations.dart';

class ChatMessagesPage extends StatefulWidget {
  final Chat chat;
  const ChatMessagesPage({Key? key, required this.chat}) : super(key: key);

  @override
  State<ChatMessagesPage> createState() => _ChatMessagesPageState();
}

class _ChatMessagesPageState extends State<ChatMessagesPage> {
  final _input = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ChatProvider>().selectChat(widget.chat);
    context.read<ChatProvider>().connectWebSocket();
  }

  @override
  void dispose() {
    context.read<ChatProvider>().disconnectWebSocket();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ChatProvider>();
    final stud = context.watch<StudentProvider>();
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    final myId = stud.userId?.toString() ?? '';
    final title = prov.titleFor(widget.chat, stud);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Expanded(
            child: prov.messages.isEmpty
                ? Center(child: Text(localizations.noMessages))
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: prov.messages.length,
                    itemBuilder: (_, i) {
                      final m = prov.messages[prov.messages.length - 1 - i];
                      final isMe = m.senderType == 'student' && m.senderId == myId;

                      final senderName = isMe
                          ? '${stud.firstName ?? ''} ${stud.lastName ?? ''}'.trim()
                          : (m.senderType == 'student'
                              ? '${m.senderFirstName ?? ''} ${m.senderLastName ?? ''}'.trim()
                              : localizations.admin);
                      final formattedTime = DateFormat('HH:mm').format(m.createdAt);

                      final messageColor = theme.brightness == Brightness.dark
                          ? (isMe ? Colors.green : Colors.grey.shade800)
                          : (isMe ? Colors.blue.shade300 : Colors.grey.shade300);

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment:
                              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                              child: Text(
                                '$senderName • $formattedTime',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: messageColor,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(
                                m.content,
                                style: TextStyle(
                                  color: isMe ? Colors.white : theme.textTheme.bodyLarge!.color,
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      decoration: InputDecoration(hintText: localizations.enterMessage),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () {
                      final text = _input.text.trim();
                      if (text.isEmpty) return;
                      prov.sendMessage(text);
                      _input.clear();
                    },
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
