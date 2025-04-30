import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

/// Класс для отправки запросов c автообновлением токена при 401.
/// При первом 401 делает POST /token/refresh/ и, если успешно, повторяет запрос.
class RefreshHttpClient extends http.BaseClient {
  final http.Client _inner = http.Client();
  final String baseUrl = "http://127.0.0.1:8000/api/v1/";

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
  static const String _baseUrl = "http://127.0.0.1:8000/api/v1/";

  /// Логин: либо через phone_number (только цифры), либо через s
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
      final prefs = await SharedPreferences.getInstance();

      // Сохраняем access/refresh
      prefs.setString('access_token', data["access"]);
      prefs.setString('refresh_token', data["refresh"]);

      if (data.containsKey("user_type")) {
        prefs.setString('user_type', data["user_type"]);
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


/// Сервис для заявок
class ApplicationService {
  /// Создание заявки POST /create_application/
  static Future<void> createApplication(String dormitoryCost, Map<String, XFile?> documents) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) throw Exception("Отсутствует токен доступа");

    final request = http.MultipartRequest(
      "POST",
      Uri.parse("http://127.0.0.1:8000/api/v1/create_application/"),
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

  /// Загрузка скриншота оплаты POST /upload_payment_screenshot/
  static Future<void> uploadPaymentScreenshot(File screenshot) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) throw Exception("Отсутствует токен доступа");

    final request = http.MultipartRequest(
      "POST",
      Uri.parse("http://127.0.0.1:8000/api/v1/upload_payment_screenshot/"),
    )
      ..headers["Authorization"] = "Bearer $token"
      ..files.add(
        http.MultipartFile.fromBytes(
          'payment_screenshot',
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

  /// Получаем статус заявки GET /application_status/
  static Future<String> fetchApplicationStatus() async {
    final client = RefreshHttpClient();
    final response = await client.get(Uri.parse("http://127.0.0.1:8000/api/v1/application_status/"));
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
  static const String baseUrl = "http://127.0.0.1:8000/api/v1/";

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
    final response = await client.get(Uri.parse("${baseUrl}questions/?search=${Uri.encodeComponent(query)}"));
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
    final response = await client.get(Uri.parse("http://127.0.0.1:8000/api/v1/chats/"));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      return List<Map<String,dynamic>>.from(decoded);
    } else {
      throw Exception("Ошибка fetchAllChats: ${response.statusCode}");
    }
  }
}

class NotificationsService {
  static Future<List<Map<String, dynamic>>> getNotifications() async {
    final client = RefreshHttpClient();
    final response = await client.get(Uri.parse("http://127.0.0.1:8000/api/v1/notifications/"));

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
      Uri.parse("http://127.0.0.1:8000/api/v1/notifications/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"notification_ids": ids}),
    );
    if (response.statusCode != 200) {
      throw Exception('Ошибка при отметке уведомлений: ${response.statusCode}');
    }
  }

  static Future<List<Map<String,dynamic>>> getAdminNotifications() async {
    final client = RefreshHttpClient();
    final response = await client.get(Uri.parse("http://127.0.0.1:8000/api/v1/notifications/admin/"));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      return List<Map<String,dynamic>>.from(decoded);
    } else {
      throw Exception("Ошибка getAdminNotifications: ${response.statusCode}");
    }
  }

  static Future<void> markAdminAsRead(List<int> ids) async {
    final client = RefreshHttpClient();
    final response = await client.post(
      Uri.parse("http://127.0.0.1:8000/api/v1/notifications/admin/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"notification_ids": ids}),
    );
    if (response.statusCode != 200) {
      throw Exception("Ошибка markAdminAsRead: ${response.statusCode}");
    }
  }
}
