class Chat {
  final String chatID; // ⇽ остаётся String
  final String? name;
  final String type;
  final int dormID;
  final int? floor;
  final bool hasNew;

  Chat({
    required this.chatID,
    this.name,
    required this.type,
    required this.dormID,
    this.floor,
    this.hasNew = false,
  });

  /// безопасное представление chatID в виде int
  int get chatIDasInt => int.tryParse(chatID) ?? 0;

  factory Chat.fromJson(Map<String, dynamic> json) => Chat(
        chatID: (json['ID'] ?? json['id']).toString(), // всегда строка
        name: json['Name'],
        type: json['Type'],
        dormID: json['DormID'],
        floor: json['Floor'],
        hasNew: json['HasNew'] ?? false,
      );
}
