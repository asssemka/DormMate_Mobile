// lib/providers/chat_provider.dart
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart' show IOWebSocketChannel;
import 'package:web_socket_channel/html.dart' show HtmlWebSocketChannel;
import 'package:provider/provider.dart'; // ←  НУЖНО!
import '../models/chat.dart';
import '../models/message.dart';
import '../services/api.dart'; // GoChatService
import 'student_provider.dart'; // для заголовков

class ChatProvider extends ChangeNotifier {
  /* ---------- public state ---------- */
  List<Chat> chats = [];
  Chat? activeChat;

  List<Message> messages = [];

  bool loading = false;
  bool isSyncing = false;
  String? syncMessage;

  /* ---------- WebSocket ---------- */
  WebSocketChannel? _socket;

  /// URL без протокола и без хвоста (пример: ws://your-host:8080)
  static const String _wsBase = 'https://student-chats.onrender.com';

  /* ---------- helpers ---------- */
  void _setLoading(bool v) {
    if (loading != v) {
      loading = v;
      notifyListeners();
    }
  }

  void _setSyncing(bool v) {
    if (isSyncing != v) {
      isSyncing = v;
      notifyListeners();
    }
  }

  void _setSyncMsg(String? m) {
    syncMessage = m;
    notifyListeners();
  }

  /* ============================================================= */
/*                       ЗАГРУЗКА ЧАТОВ                          */
/* ============================================================= */
  Future<void> fetchChats(BuildContext ctx) async {
    _setLoading(true);
    try {
      final raw = await GoChatService.fetchChats();
      final all = raw.cast<Map<String, dynamic>>().map(Chat.fromJson).toList();

      // было:  final stud = ctx.read<StudentProvider>();
      final stud = Provider.of<StudentProvider>(ctx, listen: false);

      final myDorm = stud.dormId;
      final myFloor = stud.floor;

      chats = all.where((c) {
        if (myDorm == null) return false;
        if (c.type == 'dorm' && c.dormId == myDorm) return true;
        if (c.type == 'floor' && c.dormId == myDorm && c.floor == myFloor) return true;
        return false;
      }).toList();
    } finally {
      _setLoading(false);
    }
  }

  /* ================= выбор чата + сообщения ==================== */
  Future<void> selectChat(Chat chat) async {
    // отключаемся от предыдущего сокета
    disconnectWebSocket();

    activeChat = chat;
    messages = [];
    notifyListeners();

    // история
    final raw = await GoChatService.fetchMessages(chat.chatId);
    messages = raw.cast<Map<String, dynamic>>().map(Message.fromJson).toList();

    // сбрасываем unread
    final idx = chats.indexWhere((c) => c.chatId == chat.chatId);
    if (idx != -1) chats[idx] = chats[idx].copyWith(unread: 0);

    notifyListeners();

    // подключаем WebSocket для текущего чата
    connectWebSocket(chat.chatId);
  }

  /* ---------------- отправка ---------------- */
  Future<void> sendMessage(String text) async {
    if (activeChat == null) return;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    await GoChatService.sendMessage(activeChat!.chatId, trimmed);
    // отправленное сообщение придёт обратно по WebSocket,
    // но на всякий случай перезагрузим историю:
    await _reloadActiveChat();
  }

  Future<void> _reloadActiveChat() async {
    if (activeChat == null) return;
    final raw = await GoChatService.fetchMessages(activeChat!.chatId);
    messages = raw.cast<Map<String, dynamic>>().map(Message.fromJson).toList();
    notifyListeners();
  }

  /* ---------------- синхронизация ---------------- */
  Future<void> syncChats(BuildContext ctx) async {
    _setSyncing(true);
    _setSyncMsg(null);
    try {
      await GoChatService.initAllChats();
      final res = await GoChatService.cleanupChats();
      _setSyncMsg('Удалено чатов: ${res['deleted_chats']}');
      await fetchChats(ctx);
    } catch (_) {
      _setSyncMsg('Ошибка синхронизации');
    } finally {
      _setSyncing(false);
    }
  }

  /* ---------- заголовок плитки ---------- */
  String titleFor(Chat chat, StudentProvider stud) => chat.type == 'dorm'
      ? (stud.dormName.isNotEmpty ? stud.dormName : 'Общежитие №${chat.dormId}')
      : (stud.dormName.isNotEmpty
          ? 'Этаж ${chat.floor} (${stud.dormName})'
          : 'Этаж ${chat.floor} (общежитие ${chat.dormId})');

  /* ============================================================= */
  /*                    ---  WebSocket  ---                        */
  /* ============================================================= */

  /// Открываем WebSocket для заданного chatId
  void connectWebSocket([String? chatId]) {
    if (_socket != null) return; // уже подключены

    final id = chatId ?? activeChat?.chatId;
    if (id == null) return;

    final uri = Uri.parse('$_wsBase/ws/$id'); // без двойного //

    _socket = kIsWeb ? HtmlWebSocketChannel.connect(uri) : IOWebSocketChannel.connect(uri);

    _socket!.stream.listen(
      _onSocketData,
      onError: (err) => debugPrint('WS error: $err'),
      onDone: () => debugPrint('WS closed'),
    );

    debugPrint('WebSocket connected to $uri');
  }

  /// Закрываем соединение
  void disconnectWebSocket() {
    _socket?.sink.close();
    _socket = null;
    debugPrint('WebSocket disconnected');
  }

  /// Пришёл пакет из сокета
  void _onSocketData(dynamic event) {
    try {
      final data = jsonDecode(event);
      final msg = Message.fromJson(data);

      // если сообщение относится к активному чату
      if (activeChat != null && msg.chatId == activeChat!.chatId) {
        messages.add(msg);
        notifyListeners();
      } else {
        // увеличиваем счётчик непрочитанных
        final idx = chats.indexWhere((c) => c.chatId == msg.chatId);
        if (idx != -1) {
          final unread = chats[idx].unread + 1;
          chats[idx] = chats[idx].copyWith(unread: unread);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('WS parse error: $e');
    }
  }
}
