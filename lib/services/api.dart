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

    if (accessToken != null) {
      request.headers["Authorization"] = "Bearer $accessToken";
    }

    var response = await _inner.send(request);

    if (response.statusCode == 401 && !request.headers.containsKey("X-Retry")) {
      final refreshToken = prefs.getString('refresh_token');
      if (refreshToken != null) {
        final refreshResponse = await http.post(
          Uri.parse("${baseUrl}token/refresh/"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"refresh": refreshToken}),
        );

        if (refreshResponse.statusCode == 200) {
          final data = jsonDecode(refreshResponse.body);
          final newAccess = data['access'];
          if (newAccess != null) {
            await prefs.setString('access_token', newAccess);

            final newRequest = _cloneRequest(request);
            newRequest.headers["Authorization"] = "Bearer $newAccess";
            newRequest.headers["X-Retry"] = "true";

            response = await _inner.send(newRequest);
          }
        } else {
          await prefs.clear();
        }
      }
    }
    return response;
  }

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

  static Future<bool> login(String identifier, String password) async {
    final body = RegExp(r'^\d+\$').hasMatch(identifier)
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

      prefs.setString('access_token', data["access"]);
      prefs.setString('refresh_token', data["refresh"]);

      if (data.containsKey("user_type")) {
        prefs.setString('user_type', data["user_type"]);
      }
      return true;
    }
    return false;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<Map<String, dynamic>> getStudentData() async {
    final client = RefreshHttpClient();
    final response = await client.get(Uri.parse("${_baseUrl}studentdetail/"));
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception("Ошибка загрузки данных: ${response.statusCode}");
    }
  }

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
    }
    return null;
  }

  static Future<String?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_type');
  }
}

class ApplicationService {
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

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 201) {
      throw Exception("Ошибка при создании заявки: ${response.statusCode}");
    }
  }

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

class DormService {
  final RefreshHttpClient _client = RefreshHttpClient();
  static const String _baseUrl = "http://127.0.0.1:8000/api/v1/";

  Future<List<Map<String, dynamic>>> fetchDormsRaw() async {
    final uri = Uri.parse('$_baseUrl' + 'dorms/');
    final response = await _client.get(uri);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final items = decoded['results'] ?? decoded;
      return List<Map<String, dynamic>>.from(items);
    } else {
      throw Exception("Не удалось загрузить общежития: ${response.statusCode}");
    }
  }

  Future<Map<String, dynamic>> fetchDormDetailRaw(int id) async {
    final uri = Uri.parse('$_baseUrl' + 'dorms/$id/');
    final response = await _client.get(uri);
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(
        jsonDecode(utf8.decode(response.bodyBytes)),
      );
    } else {
      throw Exception("Не удалось загрузить детали общежития (ID=$id): ${response.statusCode}");
    }
  }

  Future<List<int>> fetchDormCostsRaw() async {
    final uri = Uri.parse('$_baseUrl' + 'dorms/costs/');
    final response = await _client.get(uri);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      return List<int>.from(decoded);
    } else {
      throw Exception("Не удалось загрузить цены общежитий: ${response.statusCode}");
    }
  }

  static Future<List<Map<String, dynamic>>> getDorms() async {
    return await DormService().fetchDormsRaw();
  }
}
