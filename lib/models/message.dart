class Message {
  final int id;
  final String chatID;
  final String senderID;
  final String senderType;
  final String content;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.chatID,
    required this.senderID,
    required this.senderType,
    required this.content,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['ID'] ?? json['id'],
        chatID: json['ChatID'],
        senderID: json['SenderID'],
        senderType: json['SenderType'],
        content: json['Content'],
        createdAt: DateTime.parse(json['CreatedAt']),
      );
}
