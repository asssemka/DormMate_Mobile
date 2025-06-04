import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_slideshow/flutter_image_slideshow.dart';
import 'package:animate_do/animate_do.dart';

import '../widgets/html_iframe.dart';

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
          registerMapIframe(viewType, url);
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
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: Text('Информация об общежитии', style: GoogleFonts.montserrat()),
        backgroundColor: const Color(0xFFD50032),
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
              : FadeInUp( // 👈 Анимация плавного появления
                  duration: const Duration(milliseconds: 500),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dorm!['name'] ?? 'Без названия',
                          style: GoogleFonts.montserrat(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFD50032),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 👇 Слайдер изображений
                        _buildImageSlideshow(dorm!['images']),

                        const SizedBox(height: 24),
                        _buildCardSection([
                          _infoRow('Описание', dorm!['description'] ?? 'Описание отсутствует'),
                          _infoRow('Стоимость за 10 месяцев', '${dorm!['cost']} ₸'),
                          _infoRow('Количество мест', '${dorm!['total_places']}'),
                          _infoRow('Адрес', dorm!['address'] ?? 'Не указано'),
                        ]),

                        const SizedBox(height: 24),

                        if (kIsWeb && dorm!['address'] != null)
                          _buildCardSection([
                            const Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: Text(
                                'Карта расположения',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 300,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: buildMapIframe(viewType),
                              ),
                            ),
                          ]),
                      ],
                    ),
                  ),
                ),
    );
  }

Widget _buildImageSlideshow(dynamic imagesRaw) {
  final List<String> images = imagesRaw != null && imagesRaw.isNotEmpty
      ? List<String>.from(imagesRaw.map((i) => i['image']))
      : ['assets/banner.png'];

  return ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: ImageSlideshow(
      width: double.infinity,
      height: 220,
      initialPage: 0,
      indicatorColor: Colors.red,
      indicatorBackgroundColor: Colors.grey.shade300,
      autoPlayInterval: 3000,
      isLoop: true,
      children: images.map((url) {
        return Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Image.asset('assets/banner.png'),
        );
      }).toList(),
    ),
  );
}


  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 15.5,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 15,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSection(List<Widget> children) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
