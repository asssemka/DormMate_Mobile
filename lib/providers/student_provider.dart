// lib/providers/student_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';

import '../services/api.dart'; // RefreshHttpClient + AuthService

class StudentProvider extends ChangeNotifier {
  bool loading = false;

  // ----- профиль -----
  int? userId;
  String? firstName;
  String? lastName;

  // ----- размещение -----
  int? dormId;
  int? floor;
  String dormName = '';

  /// Загружаем профиль + данные о заселении
  Future<void> loadProfile(String lang) async {
    loading = true;
    notifyListeners();

    try {
      // 1) профиль студента
      final me = await AuthService.getStudentData();
      userId = me['id'] as int?;
      firstName = me['first_name'] ?? me['firstName'];
      lastName = me['last_name'] ?? me['lastName'];

      // 2) информация о заселении
      final recs = await _fetchStudentInDorm();
      if (recs.isNotEmpty) {
        final first = recs.first as Map<String, dynamic>;
        final dorm = first['dorm'] as Map<String, dynamic>;
        final room = first['room'] as Map<String, dynamic>;

        dormId = dorm['id'] as int?;
        dormName = dorm['name_$lang'] ?? dorm['name_ru'] ?? dorm['name_en'] ?? '';
        floor = room['floor'] as int?;
      } else {
        dormId = floor = null;
        dormName = '';
      }
    } catch (_) {
      // если что-то сломалось — обнуляем
      userId = dormId = floor = null;
      firstName = lastName = dormName = '';
    }

    loading = false;
    notifyListeners();
  }

  /// Получаем запись StudentInDorm для текущего userId
  Future<List<dynamic>> _fetchStudentInDorm() async {
    if (userId == null) return [];

    final cli = RefreshHttpClient();
    final url = Uri.parse('${djangoBaseUrl}student-in-dorm/?student_id=$userId');
    final r = await cli.get(url);

    if (r.statusCode != 200) return [];

    final d = jsonDecode(utf8.decode(r.bodyBytes));
    if (d is List) return d;
    if (d is Map && d['results'] is List) return d['results'];
    return [];
  }
}
