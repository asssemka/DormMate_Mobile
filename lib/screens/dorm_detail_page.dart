import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../widgets/html_iframe.dart'; // 👈 подключаем общий интерфейс

class DormDetailPage extends StatefulWidget {
  final int dormId;

  const DormDetailPage({super.key, required this.dormId});

  @override
  State<DormDetailPage> createState() => _DormDetailPageState();
}

class _DormDetailPageState extends State<DormDetailPage> {
  Map<String, dynamic>? dorm;
  bool loading = true;
  String? error;
  late final String viewType;

  @override
  void initState() {
    super.initState();
    viewType = 'map-${widget.dormId}';
    fetchDorm();
  }

  Future<void> fetchDorm() async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/v1/dorms/${widget.dormId}/'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        if (kIsWeb && data['address'] != null) {
          final encoded = Uri.encodeComponent(data['address']);
          final url = 'https://yandex.kz/map-widget/v1/?text=$encoded&z=17.19';
          registerMapIframe(viewType, url); // 👈 безопасно
        }

        if (!mounted) return;
        setState(() {
          dorm = data;
          loading = false;
        });
      } else {
        throw Exception('Ошибка при загрузке общежития');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultImage = 'assets/banner.png';

    return Scaffold(
      appBar: AppBar(
        title: Text('Информация об общежитии', style: GoogleFonts.montserrat()),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dorm!['name'] ?? 'Без названия',
                        style: GoogleFonts.montserrat(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          (dorm!['images'] != null && dorm!['images'].isNotEmpty)
                              ? dorm!['images'][0]['image']
                              : defaultImage,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _infoRow('Описание', dorm!['description'] ?? 'Описание отсутствует'),
                      _infoRow('Стоимость за 10 месяцев', '${dorm!['cost']} тг'),
                      _infoRow('Количество мест', '${dorm!['total_places']}'),
                      _infoRow('Адрес', dorm!['address'] ?? 'Не указано'),
                      const SizedBox(height: 24),
                      if (kIsWeb && dorm!['address'] != null)
                        SizedBox(
                          height: 300,
                          child: buildMapIframe(viewType), // 👈 безопасный вызов
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              )),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.montserrat(
                fontSize: 15,
                color: Colors.black54,
              )),
        ],
      ),
    );
  }
}
