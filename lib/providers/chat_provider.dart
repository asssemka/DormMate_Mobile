// lib/providers/chat_provider.dart

import 'package:flutter/material.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../services/api.dart'; // Где лежит GoChatService

class ChatProvider extends ChangeNotifier {
  List<Chat> chats = [];
  List<Message> messages = [];
  Chat? activeChat;

  /* ——— список чатов ——— */
  Future<void> fetchChats() async {
    final raw = await GoChatService.fetchChats();
    chats = (raw as List).map((j) => Chat.fromJson(j)).toList();
    notifyListeners();
  }

  /* ——— выбор чата ——— */
  Future<void> selectChat(Chat chat) async {
    activeChat = chat;
    final raw = await GoChatService.fetchMessages(chat.chatIDasInt);
    messages = (raw as List).map((j) => Message.fromJson(j)).toList();
    notifyListeners();
  }

  /* ——— отправка сообщения ——— */
  Future<void> sendMessage(String text) async {
    if (activeChat == null) return;
    await GoChatService.sendMessage(activeChat!.chatIDasInt, text);
    await selectChat(activeChat!); // перезагрузить сообщения
  }
}
