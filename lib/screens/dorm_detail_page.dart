import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_image_slideshow/flutter_image_slideshow.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/bottom_navigation_bar.dart';
import '../gen_l10n/app_localizations.dart';
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

  String getDormDescription(Map<String, dynamic> dorm, BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'kk') {
      return dorm['description_kk'] as String? ??
          dorm['description_ru'] as String? ??
          dorm['description_en'] as String? ??
          '';
    } else if (locale == 'en') {
      return dorm['description_en'] as String? ??
          dorm['description_ru'] as String? ??
          dorm['description_kk'] as String? ??
          '';
    } else {
      return dorm['description_ru'] as String? ??
          dorm['description_kk'] as String? ??
          dorm['description_en'] as String? ??
          '';
    }
  }

  String getDormName(Map<String, dynamic> dorm, BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'kk') {
      return dorm['name_kk'] as String? ??
          dorm['name_ru'] as String? ??
          dorm['name_en'] as String? ??
          '';
    } else if (locale == 'en') {
      return dorm['name_en'] as String? ??
          dorm['name_ru'] as String? ??
          dorm['name_kk'] as String? ??
          '';
    } else {
      return dorm['name_ru'] as String? ??
          dorm['name_kk'] as String? ??
          dorm['name_en'] as String? ??
          '';
    }
  }

  Future<void> fetchDorm() async {
    try {
      final response = await http.get(
        Uri.parse('https://dormmate-back.onrender.com/api/v1/dorms/${widget.dormId}/'),
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
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;
    final mainText = isDark ? Colors.white : Colors.black87;
    final subText = isDark ? Colors.grey[400]! : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(t.dorm_info, style: GoogleFonts.montserrat(color: mainText)),
        backgroundColor:
            theme.appBarTheme.backgroundColor ?? (isDark ? Color(0xFF232323) : Color(0xFFD50032)),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        getDormName(dorm!, context), // <--- вот так
                        style: GoogleFonts.montserrat(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Color(0xFFD50032).withOpacity(0.85) : Color(0xFFD50032),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildImageSlideshow(dorm?['images']),
                      const SizedBox(height: 24),
                      _buildCardSection([
                        _infoRow(
                          t.description,
                          dorm == null
                              ? t.description_not_found
                              : getDormDescription(dorm!, context),
                          mainText,
                          subText,
                        ),
                        _infoRow(
                          t.dorm_price_10_months,
                          '${dorm?['cost'] ?? '-'} ₸',
                          mainText,
                          subText,
                        ),
                        _infoRow(
                          t.total_places,
                          '${dorm?['total_places'] ?? '-'}',
                          mainText,
                          subText,
                        ),
                        _infoRow(
                          t.address,
                          dorm?['address'] ?? t.address_not_specified,
                          mainText,
                          subText,
                        ),
                      ], cardColor),
                      const SizedBox(height: 24),
                      if (dorm?['address'] != null)
                        _buildCardSection([
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              t.location_map,
                              style: GoogleFonts.montserrat(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: mainText,
                              ),
                            ),
                          ),
                          if (kIsWeb)
                            SizedBox(
                              height: 300,
                              child: buildMapIframe(viewType),
                            ),
                          if (!kIsWeb)
                            ElevatedButton.icon(
                              onPressed: () {
                                final encoded = Uri.encodeComponent(dorm!['address']);
                                final mapUrl = 'https://yandex.kz/maps/?text=$encoded';
                                launchUrl(Uri.parse(mapUrl));
                              },
                              icon: const Icon(Icons.map, color: Colors.white),
                              label: Text(
                                t.open_map,
                                style: GoogleFonts.montserrat(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFD50032),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape:
                                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                        ], cardColor),
                      const SizedBox(height: 16),
                      if (dorm != null)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/apply',
                                arguments: {
                                  'dorm_id': dorm!['id'],
                                  'dorm_cost': dorm!['cost'],
                                  'dorm_name': getDormName(dorm!, context),
                                },
                              );
                            },
                            icon: const Icon(Icons.assignment_turned_in, color: Colors.white),
                            label: Text(
                              t.apply_now,
                              style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFD50032),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              textStyle: GoogleFonts.montserrat(fontSize: 18),
                              shape:
                                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
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
        indicatorColor: Color(0xFFD50032),
        indicatorBackgroundColor: Colors.grey,
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

  Widget _infoRow(String title, String value, Color main, Color sub) {
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
              color: main,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 15,
              color: sub,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSection(List<Widget> children, Color cardColor) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: cardColor,
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
