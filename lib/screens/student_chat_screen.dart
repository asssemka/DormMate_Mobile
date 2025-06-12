// // lib/screens/dorm_chats_page.dart
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../providers/chat_provider.dart';
// import 'chat_messages_page.dart';

// class DormChatsPage extends StatefulWidget {
//   const DormChatsPage({Key? key}) : super(key: key);

//   @override
//   State<DormChatsPage> createState() => _DormChatsPageState();
// }

// class _DormChatsPageState extends State<DormChatsPage> {
//   @override
//   void initState() {
//     super.initState();
//     context.read<ChatProvider>().fetchChats();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final chatProv = context.watch<ChatProvider>();
//     return Scaffold(
//       appBar: AppBar(title: const Text("Чаты общежитий")),
//       body: chatProv.chats.isEmpty
//           ? const Center(child: Text("Нет чатов"))
//           : ListView.builder(
//               itemCount: chatProv.chats.length,
//               itemBuilder: (ctx, i) {
//                 final chat = chatProv.chats[i];
//                 return ListTile(
//                   title: Text(
//                     chat.type == 'dorm'
//                         ? 'Общежитие №${chat.dormId}'
//                         : 'Этаж ${chat.floor} (общежитие ${chat.dormId})',
//                   ),
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => ChatMessagesPage(chat: chat),
//                       ),
//                     );
//                   },
//                   trailing:
//                       chat.hasNew ? const Icon(Icons.mark_chat_unread, color: Colors.red) : null,
//                 );
//               },
//             ),
//     );
//   }
// }
