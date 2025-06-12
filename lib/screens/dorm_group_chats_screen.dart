import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/chat.dart';
import '../providers/chat_provider.dart';
import '../providers/student_provider.dart';
import 'chat_messages_page.dart';

class DormGroupChatsScreen extends StatefulWidget {
  const DormGroupChatsScreen({Key? key}) : super(key: key);

  @override
  State<DormGroupChatsScreen> createState() => _DormGroupChatsScreenState();
}

class _DormGroupChatsScreenState extends State<DormGroupChatsScreen> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();

    /// Запускаемся только после того, как первый кадр уже построен —
    /// тогда `Localizations` точно присутствует в дереве.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final lang = Localizations.maybeLocaleOf(context)?.languageCode ?? 'ru';

      await context.read<StudentProvider>().loadProfile(lang);
      await context.read<ChatProvider>().fetchChats(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final stud = context.watch<StudentProvider>();
    final prov = context.watch<ChatProvider>();

    // ---- прелоадер ----
    if (stud.loading || prov.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ---- фильтрация по поиску ----
    final List<Chat> visible = prov.chats.where((c) {
      if (_search.text.trim().isEmpty) return true;
      return (c.name ?? '').toLowerCase().contains(_search.text.trim().toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Групповые чаты общежития'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Синхронизация',
            onPressed: prov.isSyncing ? null : () => prov.syncChats(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Поиск…',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: visible.isEmpty
          ? const Center(child: Text('Чаты не найдены'))
          : ListView.separated(
              itemCount: visible.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final chat = visible[i];
                final title = _titleFor(chat, stud);
                final time = chat.lastTime != null ? DateFormat.Hm().format(chat.lastTime!) : '';

                return ListTile(
                  leading: chat.unread > 0
                      ? const Icon(Icons.mark_chat_unread, color: Colors.red)
                      : const Icon(Icons.chat_bubble_outline),
                  title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    chat.lastText ?? 'Нет сообщений',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(time, style: const TextStyle(fontSize: 12)),
                      if (chat.unread > 0)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('${chat.unread}',
                              style: const TextStyle(fontSize: 10, color: Colors.white)),
                        ),
                    ],
                  ),
                  onTap: () async {
                    await prov.selectChat(chat);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ChatMessagesPage(chat: chat)),
                    );
                  },
                );
              },
            ),
    );
  }

  /* ----- формируем заголовок так же, как в React-версии ----- */
  String _titleFor(Chat chat, StudentProvider stud) {
    if (chat.type == 'dorm') {
      return stud.dormName.isNotEmpty ? stud.dormName : 'Общежитие №${chat.dormId}';
    }
    return stud.dormName.isNotEmpty
        ? 'Этаж ${chat.floor} (${stud.dormName})'
        : 'Этаж ${chat.floor} (общежитие ${chat.dormId})';
  }
}
