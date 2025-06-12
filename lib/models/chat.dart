// lib/models/chat.dart
class Chat {
  // приходит строкой, но серверу нужен int
  final String chatId;
  int get idAsInt => int.tryParse(chatId) ?? 0;

  final String type; // 'dorm' | 'floor'
  final int dormId;
  final int? floor;

  final String? name;
  final String? lastText;
  final DateTime? lastTime;
  final int unread;

  Chat({
    required this.chatId,
    required this.type,
    required this.dormId,
    this.floor,
    this.name,
    this.lastText,
    this.lastTime,
    this.unread = 0,
  });

  Chat copyWith({int? unread}) => Chat(
        chatId: chatId,
        type: type,
        dormId: dormId,
        floor: floor,
        name: name,
        lastText: lastText,
        lastTime: lastTime,
        unread: unread ?? this.unread,
      );

  factory Chat.fromJson(Map<String, dynamic> j) => Chat(
        chatId: (j['chatID'] ?? j['chatId'] ?? j['id']).toString(),
        type: j['type'] as String,
        dormId: j['dormID'] ?? j['dormId'] as int,
        floor: j['floor'] as int?,
        name: j['name'] as String?,
        lastText: j['lastText'] as String?,
        lastTime: j['lastTime'] != null ? DateTime.parse(j['lastTime']) : null,
        unread: j['unread'] ?? 0,
      );
}
