import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/api.dart';
import '../widgets/banner_carousel.dart';
import '../widgets/useful_info_page.dart';
import '../widgets/bottom_navigation_bar.dart';
import '../gen_l10n/app_localizations.dart';
import 'dart:html' as html;

class HomePage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;

  const HomePage({
    Key? key,
    required this.onToggleTheme,
    required this.themeMode,
  }) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _dorms = [];

  @override
  void initState() {
    super.initState();
    _loadDorms();
  }

  Future<void> _loadDorms() async {
    try {
      final items = await DormService.getDorms();
      setState(() => _dorms = items);
    } catch (e) {
      debugPrint('Ошибка загрузки общежитий: $e');
    }
  }

  PreferredSizeWidget _buildHeader(BuildContext context) => AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFFD50032), size: 28),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
            tooltip: AppLocalizations.of(context)!.menu,
          ),
        ),
        title: Text(
          'DormMate',
          style: GoogleFonts.montserrat(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xFFD50032),
            letterSpacing: 1.2,
          ),
        ),
        // actions: [
        //   IconButton(
        //     icon: Icon(
        //       widget.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
        //       color: Color(0xFFD50032),
        //     ),
        //     tooltip: widget.themeMode == ThemeMode.dark ? "Светлая тема" : "Тёмная тема",
        //     onPressed: widget.onToggleTheme,
        //   ),
        // ],
        centerTitle: true,
      );

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

  Drawer _buildDrawer(BuildContext ctx) {
    final t = AppLocalizations.of(ctx)!;
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFFD50032)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.account_circle, color: Colors.white, size: 50),
                  const SizedBox(height: 12),
                  Text(
                    t.menu,
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Color(0xFFD50032)),
              title: Text(
                t.home,
                style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              onTap: () => Navigator.pushReplacementNamed(ctx, '/home'),
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline, color: Color(0xFFD50032)),
              title: Text(
                t.chat,
                style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              onTap: () => Navigator.pushReplacementNamed(ctx, '/chat'),
            ),
            // Кнопка смены темы
            ListTile(
              leading: Icon(
                isDark ? Icons.light_mode : Icons.dark_mode,
                color: Color(0xFFD50032),
              ),
              title: Text(
                isDark ? "Светлая тема" : "Тёмная тема",
                style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              onTap: widget.onToggleTheme,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFFD50032)),
              title: Text(
                t.logout,
                style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                await AuthService.logout();
                Navigator.pushNamedAndRemoveUntil(ctx, '/login', (route) => false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline, color: Color(0xFFD50032)),
              title: Text(
                t.chat,
                style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              onTap: () {
                final token = html.window.localStorage['flutter.access_token'];
                print('TOKEN BEFORE CHAT: $token');
                Navigator.pushNamed(context, '/dorm_chats');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDormCard(Map<String, dynamic> dorm, bool isEven, BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final images = dorm['images'] as List<dynamic>?;
    final imageUrl =
        (images != null && images.isNotEmpty) ? images[0]['image'] as String : 'assets/banner.png';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? Color(0xFF232323) : (isEven ? Colors.grey[100]! : Colors.white);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.grey[300] : Colors.grey[600];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 5,
      color: cardBg,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pushNamed(context, '/dorm/${dorm['id']}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(imageUrl, width: 90, height: 90, fit: BoxFit.cover),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getDormName(dorm, context),
                      style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),

                    const SizedBox(height: 6),
                    Text('₸${dorm['cost']}',
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        )),
                    const SizedBox(height: 8),
                    Text(dorm['address'] as String? ?? '',
                        style: GoogleFonts.montserrat(fontSize: 14, color: subtitleColor)),
                    const SizedBox(height: 8),
                    // Удобства с иконками
                    Wrap(
                      spacing: 16,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(FontAwesomeIcons.bed, size: 16, color: subtitleColor),
                            SizedBox(width: 6),
                            Text(
                              '${dorm['places'] ?? '—'} ${t.total_places}',
                              style: GoogleFonts.montserrat(fontSize: 14, color: textColor),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(FontAwesomeIcons.utensils, size: 16, color: subtitleColor),
                            SizedBox(width: 6),
                            Text(
                              t.dorm_canteen,
                              style: GoogleFonts.montserrat(fontSize: 14, color: textColor),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(FontAwesomeIcons.tshirt, size: 16, color: subtitleColor),
                            SizedBox(width: 6),
                            Text(
                              t.dorm_laundry,
                              style: GoogleFonts.montserrat(fontSize: 14, color: textColor),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 18, color: subtitleColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQSection(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : Colors.black87;
    final bodyColor = isDark ? Colors.grey[300] : Colors.black54;

    final faqItems = [
      {'question': t.faq_q1, 'answer': t.faq_a1},
      {'question': t.faq_q2, 'answer': t.faq_a2},
      {
        'question': t.faq_q3 ?? 'Кто может получить место в общежитии?',
        'answer': t.faq_a3 ?? 'Студенты, подавшие заявку и прошедшие отбор.',
      },
      {
        'question': t.faq_q4 ?? 'Как происходит заселение?',
        'answer': t.faq_a4 ??
            'Выдаётся ордер и заключается договор найма. Прописка оформляется через деканат. Самовольное заселение запрещено.',
      },
      {
        'question': t.faq_q5 ?? 'Как я могу оплатить проживание?',
        'answer':
            t.faq_a5 ?? 'Оплата производится через университетскую платёжную систему или банк.',
      },
      {
        'question': t.faq_q6 ?? 'Какие правила проживания я должен соблюдать?',
        'answer': t.faq_a6 ?? 'Соблюдение тишины, чистоты, уважение к соседям и имуществу.',
      },
      {
        'question': t.faq_q7 ?? 'Что произойдёт при нарушении правил?',
        'answer': t.faq_a7 ?? 'Предупреждение, штраф или выселение в зависимости от серьёзности.',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.faq,
            style: GoogleFonts.montserrat(
                fontSize: 22, fontWeight: FontWeight.bold, color: titleColor),
          ),
          const SizedBox(height: 12),
          ...faqItems.map((item) => ExpansionTile(
                collapsedIconColor: titleColor,
                iconColor: titleColor,
                title: Text(item['question']!,
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, color: titleColor)),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                    child: Text(item['answer']!,
                        style: GoogleFonts.montserrat(fontSize: 14, color: bodyColor)),
                  ),
                ],
              )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: _buildHeader(context),
      drawer: _buildDrawer(context),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ListView(
        children: [
          Builder(
            builder: (context) {
              final screenWidth = MediaQuery.of(context).size.width;
              final bannerHeight = screenWidth * 9 / 16; // Соотношение 16:9
              return SizedBox(
                height: bannerHeight,
                child: const BannerCarousel(),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => UsefulInfoPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFD50032), // Всегда красная!
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
                textStyle: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              child: Text(t.useful_info_students),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              t.our_dormitories,
              style: GoogleFonts.montserrat(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ..._dorms.asMap().entries.map((entry) {
            final i = entry.key;
            final dorm = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 20), // Отступ между карточками
              child: _buildDormCard(dorm, i % 2 == 0, context),
            );
          }).toList(),
          const SizedBox(height: 24),
          _buildFAQSection(context),
          const SizedBox(height: 20),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }
}
