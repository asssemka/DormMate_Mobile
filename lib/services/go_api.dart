import 'package:dio/dio.dart';
import 'dart:html' as html;

const String goBaseUrl = "https://student-chats.onrender.com/api/";

class GoChatService {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: goBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ))
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final accessToken = html.window.localStorage['flutter.access_token'];
          if (accessToken != null && accessToken.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          print(
              '[GoChatService] ERROR: ${error.response?.statusCode} on ${error.requestOptions.uri}');
          return handler.next(error);
        },
      ),
    );

  /// Получить сообщения чата
  static Future<List<dynamic>> fetchMessages(int chatId) async {
    final resp = await _dio.get('chats/$chatId/messages/');
    return resp.data;
  }

  /// Отправить сообщение
  static Future<void> sendMessage(int chatId, String text) async {
    await _dio.post('chats/$chatId/send/', data: {'text': text});
  }

  /// Создать новый чат
  static Future<int> createChat() async {
    final resp = await _dio.post('student/chats/create/');
    return resp.data['id'];
  }

  // Добавляй остальные методы по аналогии!
}
