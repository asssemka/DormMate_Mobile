import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:dio/dio.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

const String djangoBaseUrl = "https://dormmate-back.onrender.com/api/v1/";
const String goBaseUrl = "https://student-chats.onrender.com/api/";

/// Класс для отправки запросов c автообновлением токена при 401.
/// При первом 401 делает POST /token/refresh/ и, если успешно, повторяет запрос.
class RefreshHttpClient extends http.BaseClient {
  final http.Client _inner = http.Client();
  final String baseUrl = "djangoBaseUrl/api/v1/";

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');

    // Добавляем заголовок Authorization, если токен есть
    if (accessToken != null) {
      request.headers["Authorization"] = "Bearer $accessToken";
    }

    // Делаем запрос
    var response = await _inner.send(request);

    // Если сервер ответил 401, а X-Retry ещё нет
    if (response.statusCode == 401 && !request.headers.containsKey("X-Retry")) {
      final refreshToken = prefs.getString('refresh_token');
      if (refreshToken != null) {
        // Пробуем обновить токен
        final refreshResponse = await http.post(
          Uri.parse("${baseUrl}token/refresh/"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"refresh": refreshToken}),
        );

        if (refreshResponse.statusCode == 200) {
          // Сохраняем новый access
          final data = jsonDecode(refreshResponse.body);
          final newAccess = data['access'];
          if (newAccess != null) {
            await prefs.setString('access_token', newAccess);

            // Повторяем запрос c новым токеном, добавляем флаг X-Retry
            final newRequest = _cloneRequest(request);
            newRequest.headers["Authorization"] = "Bearer $newAccess";
            newRequest.headers["X-Retry"] = "true";

            response = await _inner.send(newRequest);
          }
        } else {
          // refresh не сработал, логика: разлогиниваемся
          await prefs.clear();
        }
      }
    }
    return response;
  }

  /// Клонируем исходный запрос, чтобы повторно отправить его
  http.BaseRequest _cloneRequest(http.BaseRequest original) {
    if (original is http.Request) {
      final newRequest = http.Request(original.method, original.url);
      newRequest.headers.addAll(original.headers);
      newRequest.bodyBytes = original.bodyBytes;
      return newRequest;
    } else if (original is http.MultipartRequest) {
      final newRequest = http.MultipartRequest(original.method, original.url);
      newRequest.headers.addAll(original.headers);
      newRequest.fields.addAll(original.fields);
      newRequest.files.addAll(original.files);
      return newRequest;
    }
    throw Exception("Неизвестный тип запроса: ${original.runtimeType}");
  }
}

/// Сервис аутентификации
class AuthService {
  static const String _baseUrl = "https://dormmate-back.onrender.com/api/v1/";

  static Future<bool> login(String identifier, String password) async {
    final body = RegExp(r'^\d+$').hasMatch(identifier)
        ? {"phone_number": identifier, "password": password}
        : {"s": identifier, "password": password};

    final response = await http.post(
      Uri.parse("${_baseUrl}token/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // ✅ Сохраняем токены и user_type в зависимости от платформы
      if (kIsWeb) {
        html.window.localStorage['flutter.access_token'] = data["access"];
        html.window.localStorage['flutter.refresh_token'] = data["refresh"];
        if (data.containsKey("user_type")) {
          html.window.localStorage['flutter.user_type'] = data["user_type"];
        }
      } else {
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('access_token', data["access"]);
        prefs.setString('refresh_token', data["refresh"]);
        if (data.containsKey("user_type")) {
          prefs.setString('user_type', data["user_type"]);
        }
      }

      return true;
    }

    return false;
  }

  /// Очистить SharedPreferences (выход)
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Получить access_token
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  /// Загрузить данные студента
  static Future<Map<String, dynamic>> getStudentData() async {
    final client = RefreshHttpClient();
    final response = await client.get(Uri.parse("${_baseUrl}studentdetail/"));
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception("Ошибка загрузки данных: ${response.statusCode}");
    }
  }

  /// Получаем user_type напрямую через /usertype/
  static Future<String?> fetchAndSaveUserType() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) return null;

    final url = Uri.parse("${_baseUrl}usertype/");
    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final userType = data["user_type"] as String?;
      if (userType != null) {
        await prefs.setString('user_type', userType);
        return userType;
      }
    } else {
      print("Ошибка usertype: ${response.statusCode}, body=${response.body}");
    }
    return null;
  }

  /// Читаем user_type из локального SharedPreferences
  static Future<String?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_type');
  }
}

class GoChatService {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: goBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ))
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          String? accessToken;

          if (kIsWeb) {
            accessToken = html.window.localStorage['flutter.access_token'];
          } else {
            final prefs = await SharedPreferences.getInstance();
            accessToken = prefs.getString('access_token');
          }

          print('[GoChatService] Access token: $accessToken');

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

  static Future<List<dynamic>> fetchMessages(int chatId) async {
    final resp = await _dio.get('chats/$chatId/messages/');
    return resp.data;
  }

  static Future<void> sendMessage(int chatId, String text) async {
    await _dio.post('chats/$chatId/send/', data: {'text': text});
  }

  static Future<int> createChat() async {
    final resp = await _dio.post('student/chats/create/');
    return resp.data['id'];
  }

  static Future<List<dynamic>> fetchChats() async {
    final resp = await _dio.get('chats');
    return resp.data;
  }
}

/// Сервис для заявок
class ApplicationService {
  /// Создание заявки POST /create_application/
  static Future<void> createApplication(String dormitoryCost, Map<String, XFile?> documents) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) throw Exception("Отсутствует токен доступа");

    final request = http.MultipartRequest(
      "POST",
      Uri.parse("https://dormmate-back.onrender.com/api/v1/create_application/"),
    )
      ..fields['dormitory_cost'] = dormitoryCost
      ..headers["Authorization"] = "Bearer $token";

    documents.forEach((key, file) {
      if (file != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            key,
            File(file.path).readAsBytesSync(),
            filename: file.name,
          ),
        );
      }
    });

    // Обрабатываем ответ
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 201) {
      throw Exception("Ошибка при создании заявки: ${response.statusCode}");
    }
  }

  static Future<void> uploadAvatar(File file) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse("https://dormmate-back.onrender.com/api/v1/upload-avatar/"),
    );
    request.files.add(
      http.MultipartFile.fromBytes(
        'avatar',
        file.readAsBytesSync(),
        filename: file.path.split("/").last,
      ),
    );

    final response = await request.send();
    if (response.statusCode != 200) {
      throw Exception('Не удалось загрузить аватар');
    }
  }

  /// Загрузка скриншота оплаты POST /upload_payment_screenshot/
  static Future<void> uploadPaymentScreenshot(File screenshot) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) throw Exception("Отсутствует токен доступа");

    final request = http.MultipartRequest(
      "POST",
      Uri.parse("https://dormmate-back.onrender.com//api/v1/upload_payment_screenshot/"),
    )
      ..headers["Authorization"] = "Bearer $token"
      ..files.add(
        http.MultipartFile.fromBytes(
          'upload_payment_screenshot',
          screenshot.readAsBytesSync(),
          filename: screenshot.path.split('/').last,
        ),
      );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Ошибка загрузки скриншота: ${response.statusCode}");
    }
  }

  static Future<void> uploadPaymentScreenshotWeb(Uint8List bytes, String filename) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) throw Exception("Отсутствует токен доступа");

    final request = http.MultipartRequest(
      "POST",
      Uri.parse("https://dormmate-back.onrender.com//api/v1/upload_payment_screenshot/"),
    )
      ..headers["Authorization"] = "Bearer $token"
      ..files.add(
        http.MultipartFile.fromBytes(
          'upload_payment_screenshot',
          bytes,
          filename: filename,
        ),
      );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Ошибка загрузки скриншота: ${response.statusCode}");
    }
  }

  /// Получаем статус заявки GET /application_status/
  static Future<String> fetchApplicationStatus() async {
    final client = RefreshHttpClient();
    final response = await client
        .get(Uri.parse("https://dormmate-back.onrender.com/api/v1/application_status/"));
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['status'] ?? 'Статус не найден';
    } else {
      throw Exception("Ошибка при загрузке статуса заявки: ${response.statusCode}");
    }
  }
}

/// Сервис для чата
class ChatService {
  static const String baseUrl = "https://dormmate-back.onrender.com/api/v1/";

  /// POST /student/chats/create/ -> возвращает {id:..}, 200 или 201
  static Future<int> getStudentChat() async {
    final client = RefreshHttpClient();
    final response = await client.post(Uri.parse("${baseUrl}student/chats/create/"));
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data["id"];
    } else {
      throw Exception("Ошибка получения/создания чата: ${response.statusCode}");
    }
  }

  /// GET /chats/{cId}/messages/
  static Future<List<Map<String, dynamic>>> fetchMessages(int cId) async {
    final client = RefreshHttpClient();
    final response = await client.get(Uri.parse("${baseUrl}chats/$cId/messages/"));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception("Ошибка загрузки сообщений: ${response.statusCode}");
    }
  }

  /// POST /chats/{cId}/send/ body { text: ... }
  static Future<void> sendMessage(int cId, String text) async {
    final client = RefreshHttpClient();
    final response = await client.post(
      Uri.parse("${baseUrl}chats/$cId/send/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"text": text}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Ошибка отправки сообщения: ${response.statusCode}");
    }
  }

  /// GET /questions/?search=...
  static Future<String?> searchAutoAnswer(String query) async {
    final client = RefreshHttpClient();
    final response =
        await client.get(Uri.parse("${baseUrl}questions/?search=${Uri.encodeComponent(query)}"));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      if (data.isNotEmpty && data[0]['answer'] != null) {
        return data[0]['answer'];
      }
    }
    return null;
  }

  /// POST /notifications/request-admin/, body { chat_id: cId }
  static Future<void> requestAdmin(int cId) async {
    final client = RefreshHttpClient();
    final response = await client.post(
      Uri.parse("${baseUrl}notifications/request-admin/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"chat_id": cId}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Ошибка вызова оператора: ${response.statusCode}");
    }
  }

  /// POST /chats/{cId}/end/
  static Future<void> endChat(int cId) async {
    final client = RefreshHttpClient();
    final response = await client.post(Uri.parse("${baseUrl}chats/$cId/end/"));
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Ошибка завершения чата: ${response.statusCode}");
    }
  }

  static Future<List<Map<String, dynamic>>> fetchAllChats() async {
    final client = RefreshHttpClient();
    final response =
        await client.get(Uri.parse("https://dormmate-back.onrender.com/api/v1/chats/"));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      return List<Map<String, dynamic>>.from(decoded);
    } else {
      throw Exception("Ошибка fetchAllChats: ${response.statusCode}");
    }
  }
}

class NotificationsService {
  static Future<List<Map<String, dynamic>>> getNotifications() async {
    final client = RefreshHttpClient();
    final response =
        await client.get(Uri.parse("https://dormmate-back.onrender.com/api/v1/notifications/"));

    // Проверяем статус:
    if (response.statusCode == 200) {
      // Декодируем как UTF-8
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      // Преобразуем в List<Map<String, dynamic>>
      return List<Map<String, dynamic>>.from(decoded);
    } else {
      throw Exception('Ошибка при загрузке уведомлений: ${response.statusCode}');
    }
  }

  static Future<void> markAsRead(List<int> ids) async {
    final client = RefreshHttpClient();
    final response = await client.post(
      Uri.parse("https://dormmate-back.onrender.com/api/v1/notifications/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"notification_ids": ids}),
    );
    if (response.statusCode != 200) {
      throw Exception('Ошибка при отметке уведомлений: ${response.statusCode}');
    }
  }

  static Future<List<Map<String, dynamic>>> getAdminNotifications() async {
    final client = RefreshHttpClient();
    final response = await client
        .get(Uri.parse("https://dormmate-back.onrender.com/api/v1/notifications/admin/"));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      return List<Map<String, dynamic>>.from(decoded);
    } else {
      throw Exception("Ошибка getAdminNotifications: ${response.statusCode}");
    }
  }

  static Future<void> markAdminAsRead(List<int> ids) async {
    final client = RefreshHttpClient();
    final response = await client.post(
      Uri.parse("https://dormmate-back.onrender.com/api/v1/notifications/admin/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"notification_ids": ids}),
    );
    if (response.statusCode != 200) {
      throw Exception("Ошибка markAdminAsRead: ${response.statusCode}");
    }
  }
}

class DormService {
  final RefreshHttpClient _client = RefreshHttpClient();
  static const String _baseUrl = "https://dormmate-back.onrender.com/api/v1/";

  /// Получить список общежитий в "сыром" формате
  Future<List<Map<String, dynamic>>> fetchDormsRaw() async {
    final uri = Uri.parse('$_baseUrl' + 'dorms/');
    final response = await _client.get(uri);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final items = decoded['results'] ?? decoded;
      return List<Map<String, dynamic>>.from(items);
    } else {
      throw Exception("Не удалось загрузить общежития: \${response.statusCode}");
    }
  }

  /// Получить детали конкретного общежития по ID
  Future<Map<String, dynamic>> fetchDormDetailRaw(int id) async {
    final uri = Uri.parse('$_baseUrl' + 'dorms/\$id/');
    final response = await _client.get(uri);
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(
        jsonDecode(utf8.decode(response.bodyBytes)),
      );
    } else {
      throw Exception("Не удалось загрузить детали общежития (ID=\$id): \${response.statusCode}");
    }
  }

  /// Получить список цен общежитий
  Future<List<int>> fetchDormCostsRaw() async {
    final uri = Uri.parse('$_baseUrl' + 'dorms/costs/');
    final response = await _client.get(uri);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      return List<int>.from(decoded);
    } else {
      throw Exception("Не удалось загрузить цены общежитий: \${response.statusCode}");
    }
  }

  /// Статический метод для быстрого получения списка общежитий без инстанса сервиса
  static Future<List<Map<String, dynamic>>> getDorms() async {
    return await DormService().fetchDormsRaw();
  }
}
