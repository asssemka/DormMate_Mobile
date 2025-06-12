// lib/models/message.dart
class Message {
  final int id;
  final String chatId; // dorm_1, floor_1_3 …
  final String senderId; // строкой, как приходит из Go
  final String senderType; // student | admin
  final String content;
  final DateTime createdAt;
  final String senderFirstName;
  final String senderLastName;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderType,
    required this.content,
    required this.createdAt,
    required this.senderFirstName,
    required this.senderLastName,
  });

  factory Message.fromJson(Map<String, dynamic> j) => Message(
        id: j['ID'] ?? j['id'] ?? 0,
        chatId: (j['ChatID'] ?? j['chatID']).toString(),
        senderId: (j['SenderID'] ?? j['senderID']).toString(),
        senderType: j['SenderType'] ?? j['senderType'] ?? 'student',
        content: j['Content'] ?? j['content'] ?? '',
        createdAt: DateTime.parse(j['CreatedAt'] ?? j['createdAt']),
        senderFirstName: j['senderFirstName'] ?? '',
        senderLastName: j['senderLastName'] ?? '',
      );
}
